//
//  InboxView.swift
//  FoodTree
//
//  Notifications and messages inbox
//

import SwiftUI

struct InboxView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedFilter: NotificationFilter = .all
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case posts = "Posts"
        case updates = "Updates"
    }
    
    var filteredNotifications: [AppNotification] {
        let notifications = appState.notifications
        
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.read }
        case .posts:
            return notifications.filter { $0.type == .newPost }
        case .updates:
            return notifications.filter { $0.type == .runningLow || $0.type == .extended || $0.type == .expired }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter,
                                count: countFor(filter)
                            ) {
                                selectedFilter = filter
                                FTHaptics.light()
                            }
                        }
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                }
                .padding(.vertical, 12)
                .background(Color.bgElev2Card)
                
                Divider()
                
                if filteredNotifications.isEmpty {
                    EmptyInboxView(filter: selectedFilter)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredNotifications) { notification in
                                NotificationRow(notification: notification)
                                    .onTapGesture {
                                        markAsRead(notification)
                                        FTHaptics.light()
                                    }
                                
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .background(Color.bgElev1)
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !filteredNotifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            markAllAsRead()
                            FTHaptics.medium()
                        }) {
                            Text("Mark all read")
                                .font(.system(size: 15))
                                .foregroundColor(.brandPrimary)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Seed notifications if empty
            if appState.notifications.isEmpty {
                appState.notifications = MockData.generateNotifications()
            }
        }
    }
    
    private func countFor(_ filter: NotificationFilter) -> Int {
        switch filter {
        case .all:
            return appState.notifications.count
        case .unread:
            return appState.notifications.filter { !$0.read }.count
        case .posts:
            return appState.notifications.filter { $0.type == .newPost }.count
        case .updates:
            return appState.notifications.filter { $0.type == .runningLow || $0.type == .extended || $0.type == .expired }.count
        }
    }
    
    private func markAsRead(_ notification: AppNotification) {
        if let index = appState.notifications.firstIndex(where: { $0.id == notification.id }) {
            appState.notifications[index].read = true
        }
    }
    
    private func markAllAsRead() {
        for index in appState.notifications.indices {
            appState.notifications[index].read = true
        }
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .inkMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.strokeSoft)
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .inkSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.brandPrimary : Color.bgElev1)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    
    private var iconName: String {
        switch notification.type {
        case .newPost: return "leaf.circle.fill"
        case .runningLow: return "exclamationmark.triangle.fill"
        case .extended: return "clock.arrow.circlepath"
        case .nearby: return "location.circle.fill"
        case .expired: return "xmark.circle.fill"
        }
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .newPost: return .brandPrimary
        case .runningLow: return .stateWarn
        case .extended: return .brandPrimary
        case .nearby: return .brandPrimary
        case .expired: return .inkMuted
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.system(size: 16, weight: notification.read ? .medium : .semibold))
                    .foregroundColor(.inkPrimary)
                
                Text(notification.body)
                    .font(.system(size: 15))
                    .foregroundColor(.inkSecondary)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.timestamp))
                    .font(.system(size: 13))
                    .foregroundColor(.inkMuted)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.read {
                Circle()
                    .fill(Color.brandPrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(FTLayout.paddingM)
        .background(notification.read ? Color.clear : Color.brandPrimary.opacity(0.02))
        .contentShape(Rectangle())
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        let minutes = Int(seconds / 60)
        
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours)h ago"
            } else {
                return "\(hours / 24)d ago"
            }
        }
    }
}

// MARK: - Empty Inbox View
struct EmptyInboxView: View {
    let filter: InboxView.NotificationFilter
    
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
        switch filter {
        case .all: return "tray"
        case .unread: return "checkmark.circle"
        case .posts: return "leaf"
        case .updates: return "bell.slash"
        }
    }
    
    private var emptyTitle: String {
        switch filter {
        case .all: return "No notifications yet"
        case .unread: return "You're all caught up!"
        case .posts: return "No new posts"
        case .updates: return "No updates"
        }
    }
    
    private var emptyMessage: String {
        switch filter {
        case .all: return "We'll notify you when there's free food nearby"
        case .unread: return "Check back later for new updates"
        case .posts: return "New food posts will appear here"
        case .updates: return "Post updates will appear here"
        }
    }
}

