import Foundation
import Supabase
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseConfig.shared.client
    
    private init() {
        Task {
            await checkSession()
        }
    }
    
    @MainActor
    func checkSession() async {
        do {
            let session = try await client.auth.session
            let user = session.user
            await fetchProfile(userId: user.id)
            isAuthenticated = true
        } catch {
            // No session or error
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // Sign up with email and password
    @MainActor
    func signUp(email: String, password: String, role: UserRole) async -> Bool {
        guard email.hasSuffix("@stanford.edu") else {
            errorMessage = "Please use a Stanford email (@stanford.edu)"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create auth user
            let response = try await client.auth.signUp(
                email: email,
                password: password
            )
            
            let user = response.user
            
            // Create profile
            let newProfile = UserProfile(
                id: user.id,
                email: email,
                fullName: email.components(separatedBy: "@").first,
                role: role,
                isVerifiedOrganizer: false,
                avatarUrl: nil,
                dietaryPreferences: [],
                searchRadiusMiles: 1.0,
                notificationPreferences: ["new_posts": true, "running_low": true, "post_updates": true],
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await client.database
                .from("profiles")
                .insert(newProfile)
                .execute()
            
            // Fetch profile and authenticate
            await fetchProfile(userId: user.id)
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    // Sign in with email and password
    @MainActor
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            let user = session.user
            await fetchProfile(userId: user.id)
            isAuthenticated = true
            isLoading = false
            return true
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    @MainActor
    func signOut() async {
        do {
            try await client.auth.signOut()
            isAuthenticated = false
            currentUser = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func fetchProfile(userId: UUID) async {
        do {
            let profile: UserProfile = try await client.database
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            self.currentUser = profile
        } catch {
            print("Error fetching profile: \(error)")
        }
    }
}
