//
//  RootTabView.swift
//  FoodTree
//
//  Root tab navigation with floating action button
//

import SwiftUI

struct RootTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .map
    @State private var showPostComposer = false
    @State private var scrollOffset: CGFloat = 0
    
    enum Tab: String, CaseIterable {
        case map = "Map"
        case feed = "Feed"
        case post = "Post"
        case inbox = "Inbox"
        case profile = "Profile"
        
        var icon: String {
            switch self {
            case .map: return "map.fill"
            case .feed: return "list.bullet"
            case .post: return "plus.circle.fill"
            case .inbox: return "bell.fill"
            case .profile: return "person.fill"
            }
        }
        
        var iconUnselected: String {
            switch self {
            case .map: return "map"
            case .feed: return "list.bullet"
            case .post: return "plus.circle"
            case .inbox: return "bell"
            case .profile: return "person"
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .map:
                    MapView()
                case .feed:
                    FeedView()
                case .post:
                    EmptyView()
                case .inbox:
                    InboxView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 0) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        if tab == .post {
                            // Center FAB
                            Button(action: {
                                FTHaptics.light()
                                showPostComposer = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.brandPrimary)
                                        .frame(width: 56, height: 56)
                                        .ftShadow(radius: 12, opacity: 0.3)
                                    
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(y: -20)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel("Post food")
                        } else {
                            TabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                unreadCount: tab == .inbox ? appState.notifications.filter { !$0.read }.count : 0
                            ) {
                                withAnimation(FTAnimation.easeInOut) {
                                    selectedTab = tab
                                }
                                FTHaptics.light()
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(
                    Color.bgElev2Card
                        .ignoresSafeArea()
                )
            }
        }
        .fullScreenCover(isPresented: $showPostComposer) {
            PostComposerView(isPresented: $showPostComposer)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let tab: RootTabView.Tab
    let isSelected: Bool
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? tab.icon : tab.iconUnselected)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .brandPrimary : .inkMuted)
                        .frame(height: 28)
                    
                    // Unread badge
                    if unreadCount > 0 {
                        Circle()
                            .fill(Color.brandSecondary)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Text("\(min(unreadCount, 9))")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 8, y: -4)
                    }
                }
                
                Text(tab.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .brandPrimary : .inkMuted)
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(tab.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(unreadCount > 0 ? "\(unreadCount) unread" : "")
    }
}

