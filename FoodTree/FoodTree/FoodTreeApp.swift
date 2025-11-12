//
//  FoodTreeApp.swift
//  FoodTree
//
//  A playful, elegant iOS app for discovering leftover food on campus
//

import SwiftUI
import Combine

@main
struct FoodTreeApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if appState.hasCompletedOnboarding {
                RootTabView()
                    .environmentObject(appState)
            } else {
                OnboardingView()
                    .environmentObject(appState)
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

enum UserRole: String, CaseIterable {
    case student = "Student"
    case organizer = "Organizer"
}

