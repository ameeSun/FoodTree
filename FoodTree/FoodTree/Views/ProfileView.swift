//
//  ProfileView.swift
//  TreeBites
//
//  User profile and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showOrganizerDashboard = false
    @State private var showCommunityGuidelines = false
    @State private var showDeleteConfirm1 = false
    @State private var showDeleteConfirm2 = false
    @State private var isDeletingAccount = false
    @State private var deleteErrorMessage: String?
    @State private var showDeleteError = false

    private var currentUser: UserProfile? {
        AuthService.shared.currentUser
    }
    
    private var userRole: UserRole {
        appState.userRole
    }
    
    private var userDisplayName: String {
        if let fullName = currentUser?.fullName, !fullName.isEmpty {
            return fullName
        } else if let email = currentUser?.email {
            return email.components(separatedBy: "@").first ?? "User"
        } else {
            return "User"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.brandPrimary.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.brandPrimary)
                            )
                        
                        VStack(spacing: 4) {
                            Text(userDisplayName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                            
                            Text(currentUser?.email ?? "email@stanford.edu")
                                .font(.system(size: 16))
                                .foregroundColor(.inkSecondary)
                            
                            Text(userRole.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.inkMuted)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.top, 20)
                    
                    if userRole == .organizer {
                        // Organizer dashboard link
                        Button(action: {
                            showOrganizerDashboard = true
                            FTHaptics.light()
                        }) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.brandPrimary)
                                
                                Text("Organizer Dashboard")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.inkPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.inkMuted)
                            }
                            .padding(FTLayout.paddingM)
                            .background(Color.bgElev2Card)
                            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                            .ftShadow()
                        }
                        .padding(.horizontal, FTLayout.paddingM)
                    }
                    
                    Divider()
                        .padding(.horizontal, FTLayout.paddingM)
                    
                    // Settings sections
                    VStack(alignment: .leading, spacing: 16) {
                        SettingsSection(title: "About") {
                            SettingsRow(
                                icon: "doc.text",
                                title: "Community Guidelines",
                                value: nil,
                                action: {
                                    showCommunityGuidelines = true
                                }
                            )
                        }
                        
                        SettingsSection(title: "Account") {
                            SettingsRow(
                                icon: "arrow.right.square",
                                title: "Sign Out",
                                value: nil,
                                destructive: true,
                                action: {
                                    Task {
                                        await AuthService.shared.signOut()
                                    }
                                }
                            )
                        }
                        
                        SettingsRow(
                            icon: "trash",
                            title: isDeletingAccount ? "Deleting..." : "Delete Account",
                            value: nil,
                            destructive: true,
                            action: {
                                showDeleteConfirm1 = true
                            }
                        )
                        .disabled(isDeletingAccount)
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                    
                    // Version info
                    Text("TreeBites v1.0.0 • Made at Stanford")
                        .font(.system(size: 13))
                        .foregroundColor(.inkMuted)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                }
            }
            .background(Color.bgElev1)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .confirmationDialog(
                "Delete your account?",
                isPresented: $showDeleteConfirm1,
                titleVisibility: .visible
            ) {
                Button("Continue", role: .destructive) { showDeleteConfirm2 = true }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove your profile info but keep your posts labeled as “Deleted user”.")
            }
            .confirmationDialog(
                "This can’t be undone.",
                isPresented: $showDeleteConfirm2,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        isDeletingAccount = true
                        defer { isDeletingAccount = false }

                        do {
                            try await AccountService.shared.deleteAccount()
                            // If deleteAccount() already signs out, you're done.
                            // If not, you can call: await AuthService.shared.signOut()
                        } catch {
                            deleteErrorMessage = error.localizedDescription
                            showDeleteError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will be signed out and your profile will be anonymized.")
            }
            .alert("Couldn’t delete account", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage ?? "Please try again.")
            }
        }
        .sheet(isPresented: $showOrganizerDashboard) {
            OrganizerDashboardView()
        }
        .sheet(isPresented: $showCommunityGuidelines) {
            CommunityGuidelinesView()
        }
    }
    
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.inkMuted)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.bgElev2Card)
            .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
            .ftShadow()
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String?
    var highlighted: Bool = false
    var destructive: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            FTHaptics.light()
            action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(destructive ? .stateError : (highlighted ? .brandPrimary : .inkSecondary))
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(destructive ? .stateError : .inkPrimary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundColor(.inkMuted)
                }
                
                if highlighted {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.stateWarn)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.inkMuted)
            }
            .padding(FTLayout.paddingM)
            .contentShape(Rectangle())
        }
        
        if !destructive {
            Divider()
                .padding(.leading, 56)
        }
    }
}

// MARK: - Settings View (Full Screen)
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            Form {
                Section("Dietary Preferences") {
                    ForEach(DietaryTag.allCases) { tag in
                        Toggle(isOn: Binding(
                            get: { appState.dietaryPreferences.contains(tag) },
                            set: { isOn in
                                if isOn {
                                    appState.dietaryPreferences.insert(tag)
                                } else {
                                    appState.dietaryPreferences.remove(tag)
                                }
                                FTHaptics.light()
                            }
                        )) {
                            HStack {
                                Image(systemName: tag.icon)
                                Text(tag.displayName)
                            }
                        }
                        .tint(.brandPrimary)
                    }
                }
                
                Section("Search Radius") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(String(format: "%.1f miles", appState.radiusPreference))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.brandPrimary)
                        
                        Slider(value: $appState.radiusPreference, in: 0.25...3.0, step: 0.25)
                            .tint(.brandPrimary)
                            .onChange(of: appState.radiusPreference) { _ in
                                FTHaptics.light()
                            }
                    }
                }
                
                Section("Notifications") {
                    Toggle("New posts nearby", isOn: .constant(true))
                        .tint(.brandPrimary)
                    Toggle("Running low alerts", isOn: .constant(true))
                        .tint(.brandPrimary)
                    Toggle("Smart nudges", isOn: .constant(true))
                        .tint(.brandPrimary)
                    Toggle("Post updates", isOn: .constant(true))
                        .tint(.brandPrimary)
                }
                
                Section("Quiet Hours") {
                    DatePicker("Start", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

