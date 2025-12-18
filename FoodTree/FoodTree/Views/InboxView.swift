//
//  InboxView.swift
//  TreeBites
//
//  Notifications and messages inbox
//

import SwiftUI
import Foundation
import Combine

@MainActor
struct InboxView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var repository = NotificationRepository()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isMarkingAllRead = false
    
    // All notifications (unread and read) so history remains visible
    var allNotifications: [AppNotification] {
        appState.notifications
    }
    
    // For badge and button state
    var unreadNotifications: [AppNotification] {
        appState.notifications.filter { !$0.read }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.stateWarn)
                        
                        Text("Error Loading Notifications")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.inkPrimary)
                        
                        Text(errorMessage)
                            .font(.system(size: 15))
                            .foregroundColor(.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Try Again") {
                            Task {
                                await loadNotifications()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if allNotifications.isEmpty {
                    EmptyInboxView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(allNotifications) { notification in
                                NotificationRow(notification: notification)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        if !notification.read {
                                            Button(action: {
                                                markAsRead(notification)
                                            }) {
                                                Label("Mark as read", systemImage: "checkmark.circle.fill")
                                            }
                                            .tint(.brandPrimary)
                                        }
                                    }
                                    .highPriorityGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onEnded { _ in
                                                if !notification.read {
                                                    markAsRead(notification)
                                                    FTHaptics.medium()
                                                }
                                            }
                                    )
                                    .onTapGesture {
                                        if !notification.read {
                                            markAsRead(notification)
                                            FTHaptics.light()
                                        }
                                    }
                                
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .background(Color.bgElev1)
                    .refreshable {
                        
                    }
                }
            }
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !allNotifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task { await markAllAsRead() }
                            FTHaptics.medium()
                        }) {
                            Text("Mark all read")
                                .font(.system(size: 15))
                                .foregroundColor(.brandPrimary)
                        }
                        .disabled(isMarkingAllRead || unreadNotifications.isEmpty)
                    }
                }
            }
        }
        .onAppear {
            
            Task {
                await loadNotifications()
            }
        }
    }
    
    private func loadNotifications() async {
        
        
        isLoading = true
        errorMessage = nil
        
        do {
            let notifications = try await repository.fetchNotifications(filter: .all)
            appState.notifications = notifications
            isLoading = false
        } catch is CancellationError {
            isLoading = false
        } catch {
            // If there is no session, Supabase will throw — show a friendly message
            errorMessage = "Please sign in to view notifications."
            isLoading = false
        }
        
    }
    
    private func markAsRead(_ notification: AppNotification) {
        Task { @MainActor in
            do {
                try await repository.markAsRead(notificationId: notification.id)
                // Update local state on main actor
                if let index = appState.notifications.firstIndex(where: { $0.id == notification.id }) {
                    appState.notifications[index].read = true
                }
            } catch {
                print("Failed to mark notification as read: \(error.localizedDescription)")
            }
        }
    }
    
    private func markAllAsRead() async {
        guard !isMarkingAllRead else { return }
        isMarkingAllRead = true
        errorMessage = nil
        
        do {
            try await repository.markAllAsRead()
            
            // Mark all locally so the unread list and badge clear immediately
            for index in appState.notifications.indices {
                appState.notifications[index].read = true
            }
        } catch {
            print("Failed to mark all as read: \(error.localizedDescription)")
            errorMessage = "Failed to mark notifications as read. Please try again."
        }
        
        isMarkingAllRead = false
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
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.inkMuted.opacity(0.3))
            
            Text("You're all caught up!")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.inkPrimary)
            
            Text("Check back later for new updates")
                .font(.system(size: 15))
                .foregroundColor(.inkSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgElev1)
    }
}

