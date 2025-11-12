//
//  MapView.swift
//  FoodTree
//
//  Main map view with food pins and bottom sheet
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var sheetDetent: BottomSheet<AnyView>.Detent = .peek
    @State private var selectedPost: FoodPost?
    @State private var showFilters = false
    @State private var region = MKCoordinateRegion(
        center: MockData.stanfordCenter,
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            // Map
            Map(coordinateRegion: $region, annotationItems: viewModel.posts) { post in
                MapAnnotation(coordinate: post.location.coordinate) {
                    MapPinView(post: post, isSelected: selectedPost?.id == post.id)
                        .onTapGesture {
                            withAnimation(FTAnimation.spring) {
                                selectedPost = post
                                sheetDetent = .mid
                                region.center = post.location.coordinate
                            }
                            FTHaptics.light()
                        }
                }
            }
            .ignoresSafeArea()
            
            // Top bar
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Search bar
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.inkMuted)
                        
                        Text("Search buildings or events")
                            .font(.system(size: 16))
                            .foregroundColor(.inkMuted)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.bgElev2Card)
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                    .ftShadow()
                    .onTapGesture {
                        // Open search (stub)
                        FTHaptics.light()
                    }
                    
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
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFilters) {
            FilterView(filters: $viewModel.filters)
        }
    }
}

// MARK: - Map ViewModel
class MapViewModel: ObservableObject {
    @Published var posts: [FoodPost]
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var filters = MapFilters()
    
    init() {
        self.posts = MockData.generatePosts()
        self.userLocation = MockData.stanfordCenter
        
        // Simulate location updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.userLocation = MockData.stanfordCenter
        }
    }
    
    var hasActiveFilters: Bool {
        !filters.dietary.isEmpty || filters.distance < 3.0 || filters.onlyVerified
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

