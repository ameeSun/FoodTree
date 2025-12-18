//
//  TreeBitesApp.swift
//  TreeBites
//
//  A playful, elegant iOS app for discovering leftover food on campus
//

import SwiftUI
import Supabase
import Combine
import UserNotifications

import SwiftUI
import Supabase
import Combine
import UserNotifications

@MainActor
@main
struct TreeBitesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService.shared

    init() {
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    if authService.isAuthenticated {
                        RootTabView()
                    } else {
                        LoginView()
                    }
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(appState)
            .environmentObject(authService)   
            .onAppear {
                if let user = authService.currentUser {
                    appState.userRole = user.role
                }
            }
            .onChange(of: authService.currentUser) { user in
                if let user = user {
                    appState.userRole = user.role
                }
            }
        }
    }
}


// MARK: - App Delegate for Remote Notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    private let notificationManager = NotificationManager.shared
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        notificationManager.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        notificationManager.didFailToRegisterForRemoteNotifications(error: error)
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var hasLocationPermission: Bool = false
    @Published var hasNotificationPermission: Bool = false
    @Published var userRole: UserRole = .student
    @Published var dietaryPreferences: Set<DietaryTag> = []
    @Published var radiusPreference: Double = 1.0 // miles
    @Published var notifications: [AppNotification] = []
    
    init() {
        // Check UserDefaults for onboarding status
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
    }
}

enum UserRole: String, CaseIterable, Codable {
    case student = "student"
    case organizer = "organizer"
    case both = "both"
    
    var displayName: String {
        switch self {
        case .student:
            return "Student"
        case .organizer:
            return "Administrator"
        case .both:
            return "Student & Administrator"
        }
    }
    var hasOrganizerAccess: Bool {
        self == .organizer || self == .both
    }
}

