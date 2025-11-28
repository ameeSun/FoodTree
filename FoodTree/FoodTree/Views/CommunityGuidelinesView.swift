//
//  CommunityGuidelinesView.swift
//  TreeBites
//
//  Community guidelines and responsible sharing information
//

import SwiftUI

struct CommunityGuidelinesView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Community Guidelines")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.inkPrimary)
                        
                        Text("TreeBites is built on trust, safety, and community care. Please follow these guidelines to ensure a positive experience for everyone.")
                            .font(.system(size: 16))
                            .foregroundColor(.inkSecondary)
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                    .padding(.top, 20)
                    
                    // Guidelines sections
                    VStack(alignment: .leading, spacing: 20) {
                        GuidelinesSection(
                            title: "Food Safety",
                            icon: "checkmark.shield.fill",
                            items: [
                                "Only post food that is safe to consume",
                                "Include accurate allergen information",
                                "Food must be held at safe serving temperature",
                                "Post food within a reasonable time frame",
                                "Remove posts when food is gone or expired"
                            ]
                        )
                        
                        GuidelinesSection(
                            title: "Accurate Information",
                            icon: "doc.text.fill",
                            items: [
                                "Provide clear, honest descriptions",
                                "Include dietary tags (vegan, gluten-free, etc.)",
                                "Specify quantity accurately",
                                "Update post status when food is running low",
                                "Include clear pickup instructions"
                            ]
                        )
                        
                        GuidelinesSection(
                            title: "Respectful Sharing",
                            icon: "heart.fill",
                            items: [
                                "Be respectful in all interactions",
                                "Respond promptly to messages",
                                "Follow through on commitments",
                                "Respect pickup locations and times",
                                "Report any concerns or issues"
                            ]
                        )
                        
                        GuidelinesSection(
                            title: "Community Standards",
                            icon: "person.2.fill",
                            items: [
                                "TreeBites is for the Stanford community",
                                "Only post food you have permission to share",
                                "No selling or commercial transactions",
                                "Respect privacy and personal information",
                                "Help maintain a welcoming environment"
                            ]
                        )
                    }
                    .padding(.horizontal, FTLayout.paddingM)
                    
                    // Footer
                    VStack(spacing: 12) {
                        Text("Thank you for helping make TreeBites a safe and welcoming community!")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.inkPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("If you have questions or concerns, please reach out through the app.")
                            .font(.system(size: 14))
                            .foregroundColor(.inkSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(FTLayout.paddingM)
                    .frame(maxWidth: .infinity)
                    .background(Color.brandPrimary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                    .padding(.horizontal, FTLayout.paddingM)
                    .padding(.bottom, 40)
                }
            }
            .background(Color.bgElev1)
            .navigationTitle("Community Guidelines")
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

// MARK: - Guidelines Section
struct GuidelinesSection: View {
    let title: String
    let icon: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.brandPrimary)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.inkPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.brandPrimary)
                            .padding(.top, 2)
                        
                        Text(item)
                            .font(.system(size: 15))
                            .foregroundColor(.inkSecondary)
                    }
                }
            }
            .padding(.leading, 4)
        }
        .padding(FTLayout.paddingM)
        .background(Color.bgElev2Card)
        .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
        .ftShadow()
    }
}

