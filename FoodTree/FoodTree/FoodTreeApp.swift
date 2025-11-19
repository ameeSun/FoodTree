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
                    .onOpenURL { url in
                        handleAuthCallback(url)
                    }
            } else {
                OnboardingView()
                    .environmentObject(appState)
                    .onOpenURL { url in
                        handleAuthCallback(url)
                    }
            }
        }
    }
    
    private func handleAuthCallback(_ url: URL) {
        Task {
            do {
                try await AuthManager.shared.handleAuthCallback(url: url)
                print("✅ FoodTreeApp: Auth callback handled successfully")
            } catch {
                print("❌ FoodTreeApp: Auth callback failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var hasLocationPermission: Bool = false
    @Published var hasNotificationPermission: Bool = false
    @Published var userRole: UserRole = .student
    @Published var dietaryPreferences: Set<DietaryTag> = []
    @Published var radiusPreference: Double = 1.0 // miles
    @Published var notifications: [AppNotification] = []
    
    private let authManager = AuthManager.shared
    private let notificationRepository = NotificationRepository()
    
    init() {
        // Check UserDefaults for onboarding status
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        
        // Check auth session and load data if authenticated
        Task {
            await authManager.checkSession()
            
            if authManager.isAuthenticated {
                await loadNotifications()
                updateRoleFromProfile()
                
                // Load user preferences from profile
                if let profile = authManager.currentProfile {
                    if let dietaryPrefs = profile.dietaryPreferences as? [String] {
                        self.dietaryPreferences = Set(dietaryPrefs.compactMap { DietaryTag(rawValue: $0) })
                    }
                    self.radiusPreference = profile.searchRadiusMiles
                }
            }
        }
    }
    
    private func updateRoleFromProfile() {
        guard let profile = authManager.currentProfile else { return }
        self.userRole = profile.role == "organizer" ? .organizer : .student
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Load notifications after onboarding
        Task {
            await loadNotifications()
        }
    }
    
    func loadNotifications() async {
        do {
            self.notifications = try await notificationRepository.fetchNotifications()
            print("✅ AppState: Loaded \(notifications.count) notifications")
        } catch {
            print("❌ AppState: Failed to load notifications: \(error.localizedDescription)")
            // Keep empty array on error
            self.notifications = []
        }
    }
    
    func addNotification(_ notification: AppNotification) {
        notifications.insert(notification, at: 0)
    }
}

enum UserRole: String, CaseIterable {
    case student = "Student"
    case organizer = "Organizer"
}

