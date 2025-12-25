//
//  FeedView.swift
//  TreeBites
//
//  Vertical feed with swipe actions and pull-to-refresh
//

import SwiftUI
import Combine
import CoreLocation

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var selectedPost: FoodPost?
    @State private var showFilters = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.bgElev1.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if viewModel.isLoading {
                            // Skeleton loading
                            ForEach(0..<3) { _ in
                                FoodCardSkeleton()
                            }
                        } else if viewModel.posts.isEmpty && viewModel.errorMessage != nil {
                            // Error state - only show if no posts and there's an error
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.stateWarn)
                                
                                Text("Error Loading Posts")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.inkPrimary)
                                
                                if let errorMessage = viewModel.errorMessage {
                                    Text(errorMessage)
                                        .font(.system(size: 15))
                                        .foregroundColor(.inkSecondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                
                                Button("Try Again") {
                                    Task {
                                        await viewModel.loadPosts(locationManager: locationManager)
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else if viewModel.posts.isEmpty {
                            // Empty state
                            EmptyFeedView()
                        } else {
                            ForEach(viewModel.posts) { post in
                                FoodCard(
                                    post: post,
                                    size: .medium,
                                    userLocation: viewModel.userLocation
                                ) {
                                    selectedPost = post
                                }
                                .swipeActions(edge: .leading) {
                                    Button(action: {
                                        viewModel.savePost(post)
                                        FTHaptics.medium()
                                    }) {
                                        Label("Save", systemImage: "bookmark.fill")
                                    }
                                    .tint(.brandPrimary)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(action: {
                                        viewModel.hidePost(post)
                                        FTHaptics.light()
                                    }) {
                                        Label("Hide", systemImage: "eye.slash.fill")
                                    }
                                    .tint(.inkMuted)
                                }
                            }
                        }
                    }
                    .padding(FTLayout.paddingM)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.loadPosts(locationManager: locationManager, isRefresh: true)
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.loadPosts(locationManager: locationManager)
                }
            }
            .onChange(of: locationManager.location) { newLocation in
                if newLocation != nil {
                    Task {
                        await viewModel.loadPosts(locationManager: locationManager)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showFilters = true
                        FTHaptics.light()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.hasActiveFilters ? .brandPrimary : .inkSecondary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterView(filters: $viewModel.filters)
                    .onDisappear {
                        // Reload posts when filters change
                        Task {
                            await viewModel.loadPosts(locationManager: locationManager)
                        }
                    }
            }
            .sheet(item: $selectedPost) { post in
                FoodDetailView(post: post, isPresented: Binding(
                    get: { selectedPost != nil },
                    set: { newValue in
                        if !newValue {
                            selectedPost = nil
                        }
                    }
                ), onBlockOrganizer: { organizer in
                    viewModel.blockOrganizer(organizer)
                    selectedPost = nil
                })
            }
        }
    }
}

// MARK: - Feed ViewModel
class FeedViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var filters = MapFilters()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var savedPosts: Set<String> = []
    @Published var hiddenPosts: Set<String> = []
    @Published var blockedOrganizers: Set<String> = []
    
    private let repository = FoodPostRepository()
    
    var hasActiveFilters: Bool {
        !filters.dietary.isEmpty || filters.distance < 3.0 || filters.onlyVerified
    }
    
    func loadPosts(locationManager: LocationManager, isRefresh: Bool = false) async {
        // Clear error message at start of load (unless it's a refresh, then keep existing posts)
        
        if !isRefresh {
            await MainActor.run {
                self.isLoading = true
                self.errorMessage = nil
            }
        } else {
            // For refresh, don't show loading state, just clear error
            await MainActor.run {
                self.errorMessage = nil
            }
        }
        
        // Wait for location with timeout
        var location = locationManager.location
        if location == nil {
            // Wait up to 3 seconds for location
            for _ in 0..<30 {
                // Check for cancellation during wait
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                if Task.isCancelled {
                    await MainActor.run {
                        self.isLoading = false
                        // Don't set error message on cancellation
                    }
                    return
                }
                location = locationManager.location
                if location != nil {
                    break
                }
            }
        }
        
        // Check for cancellation again
        if Task.isCancelled {
            await MainActor.run {
                self.isLoading = false
                // Don't set error message on cancellation
            }
            return
        }
        
        // Use fallback location if still nil
        let center = location ?? MockData.stanfordCenter
        userLocation = center
        
        // Convert distance from miles to meters
        let radiusMeters = filters.distance * 1609.34
        
        // Convert filters
        let postFilters = filters.toPostFilters()
        
        do {
            let fetchedPosts = try await repository.fetchNearbyPosts(
                center: center,
                radiusMeters: radiusMeters,
                filters: postFilters
            )
            
            await MainActor.run {
                // Filter out hidden posts
                self.posts = fetchedPosts.filter {
                    !hiddenPosts.contains($0.id) && !blockedOrganizers.contains($0.organizer.id)
                }
                self.isLoading = false
                self.errorMessage = nil // Clear any previous errors on success
            }
        } catch is CancellationError {
            // Ignore cancellation errors from refreshable - don't show error, keep existing posts
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = nil // Clear error on cancellation
                // Keep existing posts - don't clear them
            }
        } catch {
            await MainActor.run {
                // Only set error if we don't have existing posts
                // If we have posts, keep showing them and don't show error
                if self.posts.isEmpty {
                    self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                } else {
                    // If we have posts, just log the error but don't show it
                    print("⚠️ Failed to refresh posts: \(error.localizedDescription)")
                    self.errorMessage = nil
                }
                self.isLoading = false
            }
        }
    }
    
    func refresh() async {
        // This will be called from the view with the locationManager instance
    }
    
    func savePost(_ post: FoodPost) {
        Task {
            do {
                let isSaved = try await repository.toggleSavedPost(postId: post.id)
                await MainActor.run {
                    if isSaved {
                        savedPosts.insert(post.id)
                    } else {
                        savedPosts.remove(post.id)
                    }
                }
            } catch {
                print("Failed to save post: \(error.localizedDescription)")
            }
        }
    }
    
    func hidePost(_ post: FoodPost) {
        hiddenPosts.insert(post.id)
        posts.removeAll { $0.id == post.id }
    }
    func blockOrganizer(_ organizer: Organizer) {
        blockedOrganizers.insert(organizer.id)
        posts.removeAll { $0.organizer.id == organizer.id }
    }
}

// MARK: - Empty Feed View
struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 80))
                .foregroundColor(.brandPrimary.opacity(0.3))
            
            Text("No posts nearby yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.inkPrimary)
            
            Text("Check back soon or expand your search radius")
                .font(.system(size: 15))
                .foregroundColor(.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Skeleton Loader
struct FoodCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image skeleton
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 180)
                .shimmer(isAnimating: $isAnimating)
            
            VStack(alignment: .leading, spacing: 12) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)
                    .frame(maxWidth: 200)
                    .shimmer(isAnimating: $isAnimating)
                
                // Chips skeleton
                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 60, height: 24)
                            .shimmer(isAnimating: $isAnimating)
                    }
                }
                
                // Meta skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 16)
                    .frame(maxWidth: 250)
                    .shimmer(isAnimating: $isAnimating)
            }
            .padding(FTLayout.paddingM)
        }
        .background(Color.bgElev2Card)
        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
        .ftShadow()
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @Binding var isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.4), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            )
            .mask(content)
    }
}

extension View {
    func shimmer(isAnimating: Binding<Bool>) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

