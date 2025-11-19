//
//  AuthManager.swift
//  FoodTree
//
//  Manages Supabase authentication and user session
//

import Foundation
import Supabase
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var currentProfile: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let supabase = SupabaseConfig.shared.client
    private var cancellables = Set<AnyCancellable>()
    
    var currentUserId: UUID? {
        guard let user = currentUser else { return nil }
        return UUID(uuidString: user.id.uuidString)
    }
    
    private init() {
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Check if there's an existing session
    func checkSession() async {
        isLoading = true
        
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // Fetch profile
            await fetchProfile()
            
            print("✅ Auth: Session restored for user \(session.user.email ?? "unknown")")
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            print("ℹ️  Auth: No active session")
        }
        
        isLoading = false
    }
    
    /// Fetch user profile from database
    private func fetchProfile() async {
        guard let userId = currentUserId else { return }
        
        do {
            let profile: UserProfile = try await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            self.currentProfile = profile
            print("✅ Auth: Profile loaded - role: \(profile.role)")
        } catch {
            print("⚠️  Auth: Failed to fetch profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Management

    private struct ProfileUpdate: Encodable {
        var role: String? = nil
        var fullName: String? = nil
        var dietaryPreferences: [String]? = nil
        var searchRadiusMiles: Double? = nil
        var updatedAt: String
        
        enum CodingKeys: String, CodingKey {
            case role
            case fullName = "full_name"
            case dietaryPreferences = "dietary_preferences"
            case searchRadiusMiles = "search_radius_miles"
            case updatedAt = "updated_at"
        }
    }
    
    /// Ensure user has a profile in the database
    private func ensureProfile() async {
        guard let user = currentUser else { return }
        
        do {
            // Try to fetch existing profile
            if let profile: UserProfile = try? await supabase.database
                .from("profiles")
                .select()
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
                .value {
                
                self.currentProfile = profile
                return
            }
            
            // Create new profile if doesn't exist
            let newProfile = UserProfile(
                id: UUID(uuidString: user.id.uuidString)!,
                email: user.email ?? "",
                fullName: user.email?.components(separatedBy: "@").first,
                role: .student,
                isVerifiedOrganizer: false,
                avatarUrl: nil,
                dietaryPreferences: [],
                searchRadiusMiles: 1.0,
                notificationPreferences: ["new_posts": true, "running_low": true, "post_updates": true],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await supabase.database
                .from("profiles")
                .insert(newProfile)
                .execute()
            
            self.currentProfile = newProfile
            print("✅ Auth: Profile created for new user")
            
        } catch {
            print("⚠️  Auth: Failed to ensure profile: \(error)")
        }
    }
    
    /// Update user profile
    func updateProfile(role: String? = nil, fullName: String? = nil, dietaryPreferences: [String]? = nil, searchRadius: Double? = nil) async throws {
        guard let userId = currentUserId else {
            throw NetworkError.unauthorized
        }
        
        let payload = ProfileUpdate(
            role: role,
            fullName: fullName,
            dietaryPreferences: dietaryPreferences,
            searchRadiusMiles: searchRadius,
            updatedAt: Date().toISO8601String()
        )
        
        do {
            try await supabase.database
                .from("profiles")
                .update(payload)
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Refresh profile
            await fetchProfile()
            
            print("✅ Auth: Profile updated")
        } catch {
            print("❌ Auth: Failed to update profile: \(error)")
            throw NetworkError.serverError(error.localizedDescription)
        }
    }
    
    // MARK: - Email Authentication
    
    /// Send magic link to email (Stanford.edu only)
    func signInWithEmail(_ email: String) async throws {
        guard email.hasSuffix("@stanford.edu") else {
            throw NetworkError.invalidData
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "foodtree://auth/callback")
            )
            
            print("✅ Auth: Magic link sent to \(email)")
        } catch {
            print("❌ Auth: Failed to send magic link: \(error)")
            throw NetworkError.serverError(error.localizedDescription)
        }
    }
    
    /// Verify OTP code from email
    func verifyOTP(email: String, token: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            
            self.currentUser = session.user
            self.isAuthenticated = true
            
            // Create or fetch profile
            await ensureProfile()
            
            print("✅ Auth: OTP verified, user logged in")
        } catch {
            print("❌ Auth: OTP verification failed: \(error)")
            throw NetworkError.unauthorized
        }
    }
    
    /// Handle deep link callback from magic link
    func handleAuthCallback(url: URL) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.session(from: url)
            self.currentUser = session.user
            self.isAuthenticated = true
            
            await ensureProfile()
            
            print("✅ Auth: Session created from deep link")
        } catch {
            print("❌ Auth: Failed to handle callback: \(error)")
            throw NetworkError.unauthorized
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            
            self.currentUser = nil
            self.currentProfile = nil
            self.isAuthenticated = false
            
            print("✅ Auth: User signed out")
        } catch {
            print("❌ Auth: Sign out failed: \(error)")
        }
    }
}

// MARK: - User Profile Model

// UserProfile struct removed to avoid duplication with Models/UserProfile.swift

// MARK: - Date Extension

// Date extension removed to avoid duplication with Helpers/Extensions.swift

