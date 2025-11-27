//
//  FoodTreeApp.swift
//  FoodTree
//
//  A playful, elegant iOS app for discovering leftover food on campus
//

import SwiftUI
import Supabase
import Combine

@main
struct FoodTreeApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if appState.hasCompletedOnboarding {
                    if authService.isAuthenticated {
                        RootTabView()
                            .environmentObject(appState)
                    } else {
                        LoginView()
                    }
                } else {
                    OnboardingView()
                        .environmentObject(appState)
                }
            }
            .onAppear {
                // Sync auth state role to app state if needed
                Task { @MainActor in
                    if let user = authService.currentUser {
                        appState.userRole = user.role
                    }
                }
            }
            .onChange(of: authService.currentUser) { user in
                Task { @MainActor in
                    if let user = user {
                        appState.userRole = user.role
                    }
                }
            }
        }
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
    
    var displayName: String {
        switch self {
        case .student:
            return "Student"
        case .organizer:
            return "Administrator"
        }
    }
}

