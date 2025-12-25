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
    @State private var showSavedPosts = false
    @State private var showBlockedUsers = false
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
                    
                    if userRole.hasOrganizerAccess {
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
                        
                        SettingsSection(title: "Saved") {
                                                    SettingsRow(
                                                        icon: "bookmark.fill",
                                                        title: "Saved Posts",
                                                        value: nil,
                                                        action: {
                                                            showSavedPosts = true
                                                        }
                                                    )
                                                    
                                                    SettingsRow(
                                                        icon: "person.crop.circle.badge.xmark",
                                                        title: "Blocked Users",
                                                        value: nil,
                                                        action: {
                                                            showBlockedUsers = true
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
        .sheet(isPresented: $showSavedPosts) {
            SavedPostsView()
        }
        .sheet(isPresented: $showBlockedUsers) {
            BlockedUsersView()
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

// MARK: - Saved Posts
struct SavedPostsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var posts: [FoodPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let repository = FoodPostRepository()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView("Loading saved posts...")
                            .padding(.top, 40)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 15))
                            .foregroundColor(.stateError)
                            .multilineTextAlignment(.center)
                            .padding(.top, 40)
                            .padding(.horizontal, 20)
                    } else if posts.isEmpty {
                        Text("No saved posts yet.")
                            .font(.system(size: 16))
                            .foregroundColor(.inkSecondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(posts) { post in
                            SavedPostRow(post: post) {
                                unsave(post)
                            }
                        }
                    }
                }
                .padding(FTLayout.paddingM)
            }
            .background(Color.bgElev1)
            .navigationTitle("Saved Posts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                Task {
                    await loadSavedPosts()
                }
            }
        }
    }
    
    private func loadSavedPosts() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let saved = try await repository.fetchSavedPosts()
            await MainActor.run {
                posts = saved
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Unable to load saved posts."
                isLoading = false
            }
        }
    }
    
    private func unsave(_ post: FoodPost) {
        Task {
            do {
                _ = try await repository.toggleSavedPost(postId: post.id)
                await MainActor.run {
                    posts.removeAll { $0.id == post.id }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unable to unsave this post."
                }
            }
        }
    }
}

struct SavedPostRow: View {
    let post: FoodPost
    let onUnsave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post.title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.inkPrimary)
            
            Text(post.organizer.name)
                .font(.system(size: 14))
                .foregroundColor(.inkSecondary)
            
            Button(action: {
                onUnsave()
                FTHaptics.light()
            }) {
                Label("Unsave", systemImage: "bookmark.slash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.stateError)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.stateError.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(FTLayout.paddingM)
        .background(Color.bgElev2Card)
        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
        .ftShadow()
    }
}

// MARK: - Blocked Users
struct BlockedUsersView: View {
    @Environment(\.dismiss) var dismiss
    @State private var blockedUsers: [BlockedOrganizer] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if blockedUsers.isEmpty {
                        Text("No blocked users.")
                            .font(.system(size: 16))
                            .foregroundColor(.inkSecondary)
                            .padding(.top, 40)
                    } else {
                        ForEach(blockedUsers) { user in
                            BlockedUserRow(user: user) {
                                unblock(user)
                            }
                        }
                    }
                }
                .padding(FTLayout.paddingM)
            }
            .background(Color.bgElev1)
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                refreshBlockedUsers()
            }
        }
    }
    
    private func refreshBlockedUsers() {
        blockedUsers = BlockedOrganizerStore.load().sorted { $0.name < $1.name }
    }
    
    private func unblock(_ user: BlockedOrganizer) {
        BlockedOrganizerStore.remove(id: user.id)
        refreshBlockedUsers()
        FTHaptics.light()
    }
}

struct BlockedUserRow: View {
    let user: BlockedOrganizer
    let onUnblock: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.brandPrimary.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.name.prefix(1)))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.brandPrimary)
                )
            
            Text(user.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.inkPrimary)
            
            Spacer()
            
            Button(action: {
                onUnblock()
            }) {
                Text("Unblock")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.stateError)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.stateError.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(FTLayout.paddingM)
        .background(Color.bgElev2Card)
        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
        .ftShadow()
    }
}
