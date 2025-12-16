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
            
            // Check if profile already exists (in case user was created but profile wasn't)
            let existingProfile: UserProfile? = try? await client.database
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .single()
                .execute()
                .value
            
            // Check if email confirmation is required
            if response.session == nil {
                // Email confirmation required
                isLoading = false
                errorMessage = "Please check your email to confirm your account before signing in."
                return false
            }
            
            // Set authenticated state immediately so UI can update
            isAuthenticated = true
            isLoading = false
            
            // Create profile and fetch in background (non-blocking)
            Task { @MainActor in
                if existingProfile == nil {
                    // Create profile only if it doesn't exist
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
                    
                    do {
                        try await client.database
                            .from("profiles")
                            .insert(newProfile)
                            .execute()
                    } catch {
                        // If profile insert fails, try to fetch existing one
                        print("⚠️ Profile insert failed, trying to fetch existing profile: \(error)")
                    }
                }
                
                // Fetch profile
                await fetchProfile(userId: user.id)
            }
            
            return true
        } catch {
            isLoading = false
            let errorDescription = error.localizedDescription.lowercased()
            
            // Handle specific error cases
            if errorDescription.contains("already registered") || 
               errorDescription.contains("user already exists") ||
               errorDescription.contains("already been registered") {
                errorMessage = "This email is already registered. Please try logging in instead."
            } else if errorDescription.contains("email") && errorDescription.contains("invalid") {
                errorMessage = "Please enter a valid Stanford email address."
            } else if errorDescription.contains("password") {
                errorMessage = "Password must be at least 6 characters long."
            } else {
                errorMessage = "Sign up failed: \(error.localizedDescription)"
            }
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
            
            // Set authenticated state immediately so UI can update
            isAuthenticated = true
            isLoading = false
            
            // Fetch profile in background (non-blocking)
            Task { @MainActor in
                // Ensure profile exists (create if missing)
                await ensureProfile(userId: user.id, email: email)
                // Fetch profile
                await fetchProfile(userId: user.id)
            }
            
            return true
        } catch {
            isLoading = false
            isAuthenticated = false
            let errorDescription = error.localizedDescription.lowercased()
            
            // Handle specific error cases
            if errorDescription.contains("invalid") && errorDescription.contains("credentials") {
                errorMessage = "Invalid email or password. Please check your credentials and try again."
            } else if errorDescription.contains("email not confirmed") || 
                      errorDescription.contains("email not verified") {
                errorMessage = "Please check your email and confirm your account before signing in."
            } else if errorDescription.contains("user not found") {
                errorMessage = "No account found with this email. Please sign up first."
            } else {
                errorMessage = "Sign in failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // Ensure profile exists, create if missing
    @MainActor
    private func ensureProfile(userId: UUID, email: String) async {
        // Check if profile exists
        if let _: UserProfile = try? await client.database
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value {
            return // Profile exists
        }
        
        // Create profile if it doesn't exist
        let newProfile = UserProfile(
            id: userId,
            email: email,
            fullName: email.components(separatedBy: "@").first,
            role: .student,
            isVerifiedOrganizer: false,
            avatarUrl: nil,
            dietaryPreferences: [],
            searchRadiusMiles: 1.0,
            notificationPreferences: ["new_posts": true, "running_low": true, "post_updates": true],
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            try await client.database
                .from("profiles")
                .insert(newProfile)
                .execute()
            print("✅ Created missing profile for user \(userId)")
        } catch {
            print("⚠️ Failed to create profile: \(error)")
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
            // Check if it's a "not found" error (PGRST116 = Cannot coerce to single JSON object)
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "PGRST116" {
                // Profile doesn't exist yet - this is OK, it will be created on first post or profile update
                print("⚠️  Auth: Profile not found for user \(userId), will be created automatically")
                self.currentUser = nil
            } else {
                // Other error - log it
                print("⚠️  Auth: Failed to fetch profile: \(error)")
                self.currentUser = nil
            }
        }
    }
}
extension AuthService {
    @MainActor
    var currentUserId: UUID? { currentUser?.id }
}
