import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: UserRole? = nil
    @State private var isSignUpMode = false
    
    var body: some View {
        ZStack {
            Color.bgElev1.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo / Header
                VStack(spacing: 16) {
                    Image("TreeBitesLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                    
                    Text("Tree Bites")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.brandPrimaryInk)
                    
                    Text("Stanford Food Sharing")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.inkSecondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Auth Form
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isSignUpMode ? "Create Account" : "Welcome Back")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.inkPrimary)
                        
                        Text(isSignUpMode ? "Sign up with your Stanford email" : "Login to your account")
                            .foregroundColor(.inkSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Email Field
                    TextField("sunet@stanford.edu", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .padding()
                        .foregroundColor(.inkPrimary)
                        .background(Color.bgElev2Card)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.inkMuted.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.bgElev2Card)
                        .foregroundColor(.inkPrimary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.inkMuted.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Confirm Password (Sign-up only)
                    if isSignUpMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(Color.bgElev2Card)
                            .foregroundColor(.inkPrimary)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.inkMuted.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Role Selection
                        VStack(spacing: 12) {
                            Text("I am a...")
                                .font(.subheadline)
                                .foregroundColor(.inkSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                RoleButton(
                                    title: "Student",
                                    icon: "person.fill",
                                    isSelected: selectedRole == .student,
                                    action: { selectedRole = .student }
                                )
                                
                                RoleButton(
                                    title: "Administrator",
                                    icon: "person.3.fill",
                                    isSelected: selectedRole == .organizer,
                                    action: { selectedRole = .organizer }
                                )
                            }
                        }
                    }
                    
                    // Submit Button
                    Button(action: {
                        Task {
                            if isSignUpMode {
                                guard password == confirmPassword else {
                                    authService.errorMessage = "Passwords don't match"
                                    return
                                }
                                guard let role = selectedRole else {
                                    authService.errorMessage = "Please select a role"
                                    return
                                }
                                _ = await authService.signUp(email: email, password: password, role: role)
                            } else {
                                _ = await authService.signIn(email: email, password: password)
                            }
                        }
                    }) {
                        if authService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUpMode ? "Sign Up" : "Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(email.isEmpty || password.isEmpty || (isSignUpMode && (confirmPassword.isEmpty || selectedRole == nil)))
                    
                    // Toggle Login/Sign-up
                    Button(action: {
                        withAnimation {
                            isSignUpMode.toggle()
                            password = ""
                            confirmPassword = ""
                            selectedRole = nil
                            authService.errorMessage = nil
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.inkSecondary)
                            Text(isSignUpMode ? "Login" : "Sign Up")
                                .foregroundColor(.brandPrimary)
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }
                    
                    // Error Message
                    if let error = authService.errorMessage {
                        Text(error)
                            .foregroundColor(.stateError)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.bgElev2Card)
                .cornerRadius(24)
                .ftShadow()
                
                Spacer()
            }
            .padding(24)
        }
    }
}

struct RoleButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .brandPrimary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .inkPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.brandPrimary : Color.bgElev2Card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brandPrimary, lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.brandPrimary)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
