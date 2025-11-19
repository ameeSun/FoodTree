//
//  FeedView.swift
//  FoodTree
//
//  Vertical feed with swipe actions and pull-to-refresh
//

import SwiftUI
import Combine
import CoreLocation

struct FeedView: View {
    @StateObject private var viewModel = FeedViewModel()
    @State private var selectedPost: FoodPost?
    @State private var showDetail = false
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
                                    showDetail = true
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
                    await viewModel.refresh()
                }
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
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
                FilterView(filters: $viewModel.filters) {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
            .sheet(isPresented: $showDetail) {
                if let post = selectedPost {
                    FoodDetailView(post: post, isPresented: $showDetail)
                }
            }
        }
    }
}

// MARK: - Feed ViewModel
@MainActor
class FeedViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var filters = MapFilters()
    @Published var isLoading = false
    @Published var savedPosts: Set<String> = []
    @Published var hiddenPosts: Set<String> = []
    
    private let repository = FoodPostRepository()
    
    init() {
        // Get real user location or fallback to Stanford center
        self.userLocation = LocationManager.shared.location ?? MockData.stanfordCenter
        
        // Load posts from backend
        Task {
            await refresh()
        }
    }
    
    var hasActiveFilters: Bool {
        !filters.dietary.isEmpty || filters.distance < 3.0 || filters.onlyVerified
    }
    
    func refresh() async {
        guard let center = userLocation else {
            print("⚠️ FeedViewModel: No user location available")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Convert filters to PostFilters
            let postFilters = PostFilters(
                dietary: Array(filters.dietary.map { $0.rawValue }),
                statuses: [],
                verifiedOnly: filters.onlyVerified
            )
            
            // Use default radius of ~3 miles (5000 meters)
            let radiusMeters: Double = 5000
            
            self.posts = try await repository.fetchNearbyPosts(
                center: center,
                radiusMeters: radiusMeters,
                filters: postFilters
            )
            
            print("✅ FeedViewModel: Refreshed \(posts.count) posts")
        } catch {
            print("❌ FeedViewModel: Failed to refresh posts: \(error.localizedDescription)")
            // Keep existing posts on error
        }
    }
    
    func savePost(_ post: FoodPost) {
        Task {
            do {
                let isSaved = try await repository.toggleSavedPost(postId: post.id)
                if isSaved {
                    savedPosts.insert(post.id)
                    FTHaptics.medium()
                } else {
                    savedPosts.remove(post.id)
                }
            } catch {
                print("❌ FeedViewModel: Failed to save post: \(error.localizedDescription)")
            }
        }
    }
    
    func hidePost(_ post: FoodPost) {
        hiddenPosts.insert(post.id)
        posts.removeAll { $0.id == post.id }
        // Optionally persist to UserDefaults for session persistence
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

