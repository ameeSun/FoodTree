//
//  MapView.swift
//  TreeBites
//
//  Main map view with food pins and bottom sheet
//

import SwiftUI
import MapKit
import Combine

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @StateObject private var locationManager = LocationManager()
    @State private var sheetDetent: BottomSheet<AnyView>.Detent = .peek
    @State private var selectedPost: FoodPost?
    @State private var showFilters = false
    @State private var region = MKCoordinateRegion(
        center: MockData.stanfordCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    private var allAnnotations: [MapAnnotationItem] {
        var annotations: [MapAnnotationItem] = viewModel.posts.map { .foodPost(FoodPostAnnotation(post: $0)) }
        if let userLocation = locationManager.location {
            annotations.append(.userLocation(UserLocationAnnotation(coordinate: userLocation)))
        }
        return annotations
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(coordinateRegion: $region, annotationItems: allAnnotations) { annotation in
                let result: MapAnnotation<AnyView> = {
                    switch annotation {
                    case .foodPost(let postAnnotation):
                        return MapAnnotation(coordinate: postAnnotation.coordinate) {
                            AnyView(
                                MapPinView(post: postAnnotation.post, isSelected: selectedPost?.id == postAnnotation.post.id)
                                    .onTapGesture {
                                        withAnimation(FTAnimation.spring) {
                                            selectedPost = postAnnotation.post
                                            sheetDetent = .mid
                                            region.center = postAnnotation.coordinate
                                        }
                                        FTHaptics.light()
                                    }
                            )
                        }
                    case .userLocation(let userAnnotation):
                        return MapAnnotation(coordinate: userAnnotation.coordinate) {
                            AnyView(UserLocationPinView())
                        }
                    }
                }()
                return result
            }
            .ignoresSafeArea()
            
            // Top bar
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    
                    // Filter button
                    Button(action: {
                        showFilters.toggle()
                        FTHaptics.light()
                    }) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(viewModel.hasActiveFilters ? .brandPrimary : .inkSecondary)
                                .padding(10)
                                .background(Color.bgElev2Card)
                                .clipShape(Circle())
                                .ftShadow()
                            
                            if viewModel.hasActiveFilters {
                                Circle()
                                    .fill(Color.brandSecondary)
                                    .frame(width: 10, height: 10)
                                    .offset(x: 2, y: 2)
                            }
                        }
                    }
                    .accessibilityLabel("Filters")
                    .accessibilityHint(viewModel.hasActiveFilters ? "Active filters applied" : "No filters")
                }
                .padding(.horizontal, FTLayout.paddingM)
                .padding(.top, 60)
                .padding(.bottom, FTLayout.paddingM)
                
                Spacer()
            }
            
            // Bottom sheet with food cards
            VStack(spacing: 0) {
                Spacer()
                
                BottomSheet(
                    detent: $sheetDetent,
                    detents: [.peek, .mid, .full]
                ) {
                    AnyView(
                        Group {
                            if sheetDetent == .peek {
                                // Peek: horizontal scroll of cards
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.posts) { post in
                                            FoodCard(
                                                post: post,
                                                size: .small,
                                                userLocation: viewModel.userLocation
                                            ) {
                                                withAnimation(FTAnimation.spring) {
                                                    selectedPost = post
                                                    sheetDetent = .mid
                                                    region.center = post.location.coordinate
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, FTLayout.paddingM)
                                    .padding(.bottom, FTLayout.paddingM)
                                }
                            } else if let selectedPost = selectedPost {
                                // Mid: selected post detail
                                ScrollView {
                                    FoodDetailContent(post: selectedPost, userLocation: viewModel.userLocation)
                                        .padding(.bottom, 100)
                                }
                            } else {
                                // Mid/Full: list of all posts
                                ScrollView {
                                    VStack(spacing: 16) {
                                        ForEach(viewModel.posts) { post in
                                            FoodCard(
                                                post: post,
                                                size: .medium,
                                                userLocation: viewModel.userLocation
                                            ) {
                                                withAnimation(FTAnimation.spring) {
                                                    selectedPost = post
                                                    region.center = post.location.coordinate
                                                }
                                            }
                                        }
                                    }
                                    .padding(FTLayout.paddingM)
                                    .padding(.bottom, 100)
                                }
                            }
                        }
                    )
                }
            }
            .ignoresSafeArea()
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
        .onAppear {
            Task {
                await viewModel.loadPosts(locationManager: locationManager)
                // Update map region when location is available
                if let location = locationManager.location {
                    await MainActor.run {
                        region.center = location
                    }
                }
            }
        }
        .onChange(of: locationManager.location) { newLocation in
            if let location = newLocation {
                // Update map region to user location
                Task { @MainActor in
                    region.center = location
                }
                // Reload posts with new location
                Task {
                    await viewModel.loadPosts(locationManager: locationManager)
                }
            }
        }
    }
    
}

// MARK: - Map ViewModel
class MapViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var filters = MapFilters()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository = FoodPostRepository()
    
    var hasActiveFilters: Bool {
        !filters.dietary.isEmpty || filters.distance < 3.0 || filters.onlyVerified
    }
    
    func loadPosts(locationManager: LocationManager) async {
        isLoading = true
        errorMessage = nil
        
        // Wait for location with timeout
        var location = locationManager.location
        if location == nil {
            // Wait up to 3 seconds for location
            for _ in 0..<30 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                location = locationManager.location
                if location != nil {
                    break
                }
            }
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
                self.posts = fetchedPosts
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func refreshPosts(locationManager: LocationManager) async {
        await loadPosts(locationManager: locationManager)
    }
}

// MARK: - Map Filters
struct MapFilters {
    var dietary: Set<DietaryTag> = []
    var distance: Double = 3.0 // miles
    var timeLeft: Int = 90 // minutes
    var perishableOnly: Bool = false
    var onlyVerified: Bool = false
    var buildings: Set<String> = []
}

// MARK: - MapFilters Extension for Repository Conversion
extension MapFilters {
    func toPostFilters() -> PostFilters {
        PostFilters(
            dietary: Array(self.dietary.map { $0.rawValue }),
            statuses: [],
            verifiedOnly: self.onlyVerified
        )
    }
}

// MARK: - Filter View
struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var filters: MapFilters
    @State private var localFilters: MapFilters
    
    init(filters: Binding<MapFilters>) {
        self._filters = filters
        self._localFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Dietary preferences
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Dietary preferences")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.inkPrimary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(DietaryTag.allCases) { tag in
                                DietaryFilterChip(
                                    tag: tag,
                                    isSelected: localFilters.dietary.contains(tag)
                                ) {
                                    if localFilters.dietary.contains(tag) {
                                        localFilters.dietary.remove(tag)
                                    } else {
                                        localFilters.dietary.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Distance
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Distance")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f mi", localFilters.distance))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.brandPrimary)
                        }
                        
                        Slider(value: $localFilters.distance, in: 0.25...3.0, step: 0.25)
                            .tint(.brandPrimary)
                    }
                    
                    Divider()
                    
                    // Time left
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Time remaining")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                            
                            Spacer()
                            
                            Text("\(localFilters.timeLeft) min")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.brandPrimary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(localFilters.timeLeft) },
                            set: { localFilters.timeLeft = Int($0) }
                        ), in: 15...90, step: 15)
                            .tint(.brandPrimary)
                    }
                    
                    Divider()
                    
                    // Toggles
                    VStack(spacing: 16) {
                        Toggle("Perishable items only", isOn: $localFilters.perishableOnly)
                            .tint(.brandPrimary)
                        
                        Toggle("Verified organizers only", isOn: $localFilters.onlyVerified)
                            .tint(.brandPrimary)
                    }
                    .font(.system(size: 16))
                    
                    Divider()
                    
                    // Clear filters
                    Button(action: {
                        localFilters = MapFilters()
                        FTHaptics.light()
                    }) {
                        Text("Clear all filters")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.brandSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(FTLayout.paddingM)
            }
            .background(Color.bgElev1)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filters = localFilters
                        FTHaptics.medium()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Flow Layout (for wrapping chips)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var positions: [CGPoint]
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > width && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

