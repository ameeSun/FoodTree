//
//  OrganizerDashboardView.swift
//  FoodTree
//
//  Dashboard for organizers to manage their posts
//

import SwiftUI
import Combine

struct OrganizerDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = OrganizerViewModel()
    @State private var selectedTab: PostTab = .active
    
    enum PostTab: String, CaseIterable {
        case active = "Active"
        case low = "Low"
        case ended = "Ended"
        
        var icon: String {
            switch self {
            case .active: return "leaf.fill"
            case .low: return "exclamationmark.triangle.fill"
            case .ended: return "checkmark.circle.fill"
            }
        }
    }
    
    var filteredPosts: [FoodPost] {
        switch selectedTab {
        case .active:
            return viewModel.posts.filter { $0.status == .available }
        case .low:
            return viewModel.posts.filter { $0.status == .low }
        case .ended:
            return viewModel.posts.filter { $0.status == .gone || $0.status == .expired }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats header
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Active Posts",
                            value: "\(viewModel.posts.filter { $0.status == .available }.count)",
                            icon: "leaf.circle.fill",
                            color: .brandPrimary
                        )
                        
                        StatCard(
                            title: "Total Views",
                            value: "\(viewModel.totalViews)",
                            icon: "eye.fill",
                            color: .brandPrimary
                        )
                        
                        StatCard(
                            title: "On Their Way",
                            value: "\(viewModel.totalOnMyWay)",
                            icon: "figure.walk",
                            color: .brandPrimary
                        )
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                }
                .padding(.vertical, 16)
                .background(Color.bgElev2Card)
                
                Divider()
                
                // Tab selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(PostTab.allCases, id: \.self) { tab in
                            Button(action: {
                                selectedTab = tab
                                FTHaptics.light()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 14))
                                    
                                    Text(tab.rawValue)
                                        .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                                    
                                    let count = filteredPostsCount(for: tab)
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedTab == tab ? .white : .inkMuted)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(selectedTab == tab ? Color.white.opacity(0.3) : Color.strokeSoft)
                                            .clipShape(Capsule())
                                    }
                                }
                                .foregroundColor(selectedTab == tab ? .white : .inkSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(selectedTab == tab ? Color.brandPrimary : Color.bgElev1)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                }
                .padding(.vertical, 12)
                .background(Color.bgElev2Card)
                
                Divider()
                
                // Posts list
                if filteredPosts.isEmpty {
                    EmptyDashboardView(tab: selectedTab)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredPosts) { post in
                                OrganizerPostCard(
                                    post: post,
                                    onMarkLow: { viewModel.markAsLow(post) },
                                    onMarkGone: { viewModel.markAsGone(post) },
                                    onExtend: { viewModel.extendTime(post) },
                                    onAdjustQuantity: { quantity in
                                        viewModel.adjustQuantity(post, to: quantity)
                                    }
                                )
                            }
                        }
                        .padding(FTLayout.paddingM)
                        .padding(.bottom, 100)
                    }
                    .background(Color.bgElev1)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.brandPrimary)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func filteredPostsCount(for tab: PostTab) -> Int {
        switch tab {
        case .active:
            return viewModel.posts.filter { $0.status == .available }.count
        case .low:
            return viewModel.posts.filter { $0.status == .low }.count
        case .ended:
            return viewModel.posts.filter { $0.status == .gone || $0.status == .expired }.count
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.inkSecondary)
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.inkPrimary)
        }
        .frame(width: 140)
        .padding(FTLayout.paddingM)
        .background(Color.bgElev1)
        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
    }
}

// MARK: - Organizer Post Card
struct OrganizerPostCard: View {
    let post: FoodPost
    let onMarkLow: () -> Void
    let onMarkGone: () -> Void
    let onExtend: () -> Void
    let onAdjustQuantity: (Int) -> Void
    
    @State private var showQuantityAdjuster = false
    @State private var adjustedQuantity: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.inkPrimary)
                    
                    HStack(spacing: 8) {
                        StatusPill(status: post.status, animated: false)
                        
                        if let building = post.location.building {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 12))
                                Text(building)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.inkSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Quantity dial
                QuantityDial(
                    quantity: post.quantityApprox,
                    size: 80,
                    interactive: false
                )
            }
            
            // Metrics
            HStack(spacing: 20) {
                MetricBadge(icon: "eye.fill", value: "\(post.metrics.views)", label: "Views")
                MetricBadge(icon: "figure.walk", value: "\(post.metrics.onMyWay)", label: "On the way")
                MetricBadge(icon: "bookmark.fill", value: "\(post.metrics.saves)", label: "Saved")
            }
            
            Divider()
            
            // Actions
            VStack(spacing: 8) {
                if post.status == .available || post.status == .low {
                    HStack(spacing: 8) {
                        ActionButton(
                            title: "Adjust Qty",
                            icon: "slider.horizontal.3",
                            style: .secondary
                        ) {
                            showQuantityAdjuster = true
                            FTHaptics.light()
                        }
                        
                        ActionButton(
                            title: "Extend +15m",
                            icon: "clock.arrow.circlepath",
                            style: .secondary
                        ) {
                            onExtend()
                            FTHaptics.medium()
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if post.status == .available {
                            ActionButton(
                                title: "Mark as Low",
                                icon: "exclamationmark.triangle",
                                style: .warning
                            ) {
                                onMarkLow()
                                FTHaptics.warning()
                            }
                        }
                        
                        ActionButton(
                            title: "Mark as Gone",
                            icon: "xmark.circle",
                            style: .destructive
                        ) {
                            onMarkGone()
                            FTHaptics.warning()
                        }
                    }
                }
            }
        }
        .padding(FTLayout.paddingM)
        .background(Color.bgElev2Card)
        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
        .ftShadow()
        .sheet(isPresented: $showQuantityAdjuster) {
            QuantityAdjusterSheet(
                currentQuantity: post.quantityApprox,
                onAdjust: { newQuantity in
                    onAdjustQuantity(newQuantity)
                    FTHaptics.medium()
                }
            )
        }
    }
}

// MARK: - Metric Badge
struct MetricBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.inkPrimary)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.inkMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let title: String
    let icon: String
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, warning, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .brandPrimary
            case .secondary: return .bgElev1
            case .warning: return .stateWarn.opacity(0.1)
            case .destructive: return .stateError.opacity(0.1)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .inkPrimary
            case .warning: return .stateWarn
            case .destructive: return .stateError
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusPill))
        }
    }
}

// MARK: - Quantity Adjuster Sheet
struct QuantityAdjusterSheet: View {
    @Environment(\.dismiss) var dismiss
    let currentQuantity: Int
    let onAdjust: (Int) -> Void
    
    @State private var newQuantity: Int
    
    init(currentQuantity: Int, onAdjust: @escaping (Int) -> Void) {
        self.currentQuantity = currentQuantity
        self.onAdjust = onAdjust
        self._newQuantity = State(initialValue: currentQuantity)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                QuantityDial(
                    quantity: newQuantity,
                    size: 160,
                    interactive: false
                )
                
                QuantitySlider(quantity: $newQuantity, range: 0...100)
                    .padding(.horizontal, FTLayout.paddingL)
                
                Spacer()
                
                Button(action: {
                    onAdjust(newQuantity)
                    dismiss()
                }) {
                    Text("Update Quantity")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.brandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusButton))
                }
                .padding(.horizontal, FTLayout.paddingL)
                .padding(.bottom, 40)
            }
            .background(Color.bgElev1)
            .navigationTitle("Adjust Quantity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Empty Dashboard View
struct EmptyDashboardView: View {
    let tab: OrganizerDashboardView.PostTab
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 64))
                .foregroundColor(.inkMuted.opacity(0.3))
            
            Text(emptyTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.inkPrimary)
            
            Text(emptyMessage)
                .font(.system(size: 15))
                .foregroundColor(.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgElev1)
    }
    
    private var iconName: String {
        switch tab {
        case .active: return "leaf.circle"
        case .low: return "exclamationmark.triangle"
        case .ended: return "checkmark.circle"
        }
    }
    
    private var emptyTitle: String {
        switch tab {
        case .active: return "No active posts"
        case .low: return "No low posts"
        case .ended: return "No ended posts"
        }
    }
    
    private var emptyMessage: String {
        switch tab {
        case .active: return "Create a post to start sharing food with students"
        case .low: return "Posts running low will appear here"
        case .ended: return "Completed and expired posts will appear here"
        }
    }
}

// MARK: - Organizer ViewModel
@MainActor
class OrganizerViewModel: ObservableObject {
    @Published var posts: [FoodPost] = []
    @Published var isLoading = false
    
    private let repository = FoodPostRepository()
    
    init() {
        // Load user's posts from backend
        Task {
            await loadMyPosts()
        }
    }
    
    var totalViews: Int {
        posts.reduce(0) { $0 + $1.metrics.views }
    }
    
    var totalOnMyWay: Int {
        posts.reduce(0) { $0 + $1.metrics.onMyWay }
    }
    
    func loadMyPosts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.posts = try await repository.fetchMyPosts()
            print("✅ OrganizerViewModel: Loaded \(posts.count) posts")
        } catch {
            print("❌ OrganizerViewModel: Failed to load posts: \(error.localizedDescription)")
            // Keep empty array on error
            self.posts = []
        }
    }
    
    func markAsLow(_ post: FoodPost) {
        Task {
            do {
                try await repository.markAsLow(postId: post.id)
                await loadMyPosts() // Refresh
                FTHaptics.warning()
            } catch {
                print("❌ OrganizerViewModel: Failed to mark as low: \(error.localizedDescription)")
            }
        }
    }
    
    func markAsGone(_ post: FoodPost) {
        Task {
            do {
                try await repository.markAsGone(postId: post.id)
                await loadMyPosts() // Refresh
                FTHaptics.warning()
            } catch {
                print("❌ OrganizerViewModel: Failed to mark as gone: \(error.localizedDescription)")
            }
        }
    }
    
    func extendTime(_ post: FoodPost) {
        Task {
            do {
                try await repository.extendPost(postId: post.id, additionalMinutes: 15)
                await loadMyPosts() // Refresh
                FTHaptics.medium()
            } catch {
                print("❌ OrganizerViewModel: Failed to extend time: \(error.localizedDescription)")
            }
        }
    }
    
    func adjustQuantity(_ post: FoodPost, to quantity: Int) {
        Task {
            do {
                try await repository.adjustQuantity(postId: post.id, newQuantity: quantity)
                await loadMyPosts() // Refresh
                FTHaptics.medium()
            } catch {
                print("❌ OrganizerViewModel: Failed to adjust quantity: \(error.localizedDescription)")
            }
        }
    }
}

