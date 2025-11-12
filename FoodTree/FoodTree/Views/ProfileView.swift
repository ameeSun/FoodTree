//
//  ProfileView.swift
//  FoodTree
//
//  User profile and settings
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false
    @State private var showOrganizerDashboard = false
    
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
                            Text("Stanford Student")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.inkPrimary)
                            
                            Text("student@stanford.edu")
                                .font(.system(size: 16))
                                .foregroundColor(.inkSecondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Role toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Text("I'm posting as")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.inkSecondary)
                            .padding(.horizontal, FTLayout.paddingM)
                        
                        HStack(spacing: 12) {
                            ForEach(UserRole.allCases, id: \.self) { role in
                                Button(action: {
                                    appState.userRole = role
                                    FTHaptics.medium()
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: role == .student ? "person.fill" : "building.2.fill")
                                            .font(.system(size: 24))
                                        
                                        Text(role.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                    }
                                    .foregroundColor(appState.userRole == role ? .white : .inkPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                    .background(appState.userRole == role ? Color.brandPrimary : Color.bgElev2Card)
                                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard)
                                            .strokeBorder(
                                                appState.userRole == role ? Color.clear : Color.strokeSoft,
                                                lineWidth: 1
                                            )
                                    )
                                    .ftShadow(opacity: appState.userRole == role ? 0.15 : 0.08)
                                }
                            }
                        }
                        .padding(.horizontal, FTLayout.paddingM)
                    }
                    
                    if appState.userRole == .organizer {
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
                        SettingsSection(title: "Preferences") {
                            SettingsRow(icon: "fork.knife", title: "Dietary filters", value: dietaryFiltersSummary)
                            SettingsRow(icon: "location.circle", title: "Search radius", value: String(format: "%.1f mi", appState.radiusPreference))
                            SettingsRow(icon: "bell.badge", title: "Notifications", value: "Enabled")
                            SettingsRow(icon: "moon", title: "Quiet hours", value: "10 PM - 8 AM")
                        }
                        
                        SettingsSection(title: "About") {
                            SettingsRow(icon: "questionmark.circle", title: "Help & Support", value: nil)
                            SettingsRow(icon: "doc.text", title: "Community Guidelines", value: nil)
                            SettingsRow(icon: "shield.checkered", title: "Privacy & Safety", value: nil)
                        }
                        
                        SettingsSection(title: "Account") {
                            SettingsRow(icon: "checkmark.seal", title: "Verify as organizer", value: nil, highlighted: appState.userRole == .organizer)
                            SettingsRow(icon: "arrow.right.square", title: "Sign Out", value: nil, destructive: true)
                        }
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                    
                    // Version info
                    Text("FoodTree v1.0.0 • Made at Stanford")
                        .font(.system(size: 13))
                        .foregroundColor(.inkMuted)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                }
            }
            .background(Color.bgElev1)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings = true
                        FTHaptics.light()
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.inkSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showOrganizerDashboard) {
            OrganizerDashboardView()
        }
    }
    
    private var dietaryFiltersSummary: String {
        if appState.dietaryPreferences.isEmpty {
            return "None"
        } else if appState.dietaryPreferences.count == 1 {
            return appState.dietaryPreferences.first?.displayName ?? "1 selected"
        } else {
            return "\(appState.dietaryPreferences.count) selected"
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
    
    var body: some View {
        Button(action: {
            FTHaptics.light()
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

