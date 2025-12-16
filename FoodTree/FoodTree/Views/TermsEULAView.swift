//
//  TermsEULAView.swift
//  FoodTree
//
//  Created by s8579_stnfrd on 12/16/25.
//

import SwiftUI

struct TermsEULAView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("End User License Agreement & Safety")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.inkPrimary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("By using Tree Bites you agree to:")
                            .font(.headline)
                            .foregroundColor(.inkPrimary)

                        bulleted("Share only respectful, non-objectionable content. Offensive, hateful, or abusive posts are not tolerated and will be removed.")
                        bulleted("Follow Stanford policies and applicable laws while using the app.")
                        bulleted("Report any harmful or inappropriate content you encounter so we can review it promptly.")
                        bulleted("Allow moderators to remove content and suspend users who violate these rules.")
                    }
                    .padding()
                    .background(Color.bgElev2Card)
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                    .ftShadow()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Zero tolerance for objectionable content")
                            .font(.headline)
                            .foregroundColor(.inkPrimary)

                        Text("We actively moderate user-generated content. Posts that include threats, harassment, discriminatory language, or sexual content will be blocked, and accounts may be suspended or removed.")
                            .foregroundColor(.inkSecondary)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Use the report option on any post to flag problems. We review reports quickly and may restrict posting for repeat offenders.")
                            .foregroundColor(.inkSecondary)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.bgElev2Card)
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                    .ftShadow()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("License")
                            .font(.headline)
                            .foregroundColor(.inkPrimary)
                        Text("Tree Bites is provided for Stanford community members. The service is offered \"as-is\" without warranties, and you are responsible for the content you share. Misuse may lead to suspension or removal.")
                            .foregroundColor(.inkSecondary)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.bgElev2Card)
                    .clipShape(RoundedRectangle(cornerRadius: FTLayout.cornerRadiusCard))
                    .ftShadow()
                }
                .padding(.horizontal, FTLayout.paddingM)
                .padding(.bottom, 32)
                .padding(.top, 12)
                .background(Color.bgElev1)
            }
            .navigationTitle("Terms & EULA")
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

    private func bulleted(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.brandPrimary)
                .padding(.top, 2)
            Text(text)
                .foregroundColor(.inkSecondary)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TermsEULAView_Previews: PreviewProvider {
    static var previews: some View {
        TermsEULAView()
    }
}
