import SwiftUI

struct FamilyPlanView: View {
    @Environment(\.dismiss) private var dismiss

    private let features: [(icon: String, text: String)] = [
        ("person.3.fill", "Up to 6 members, one plan"),
        ("sparkles", "Unlimited AI meal scanning for all"),
        ("person.crop.rectangle.stack", "Personalized plans for everyone"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Illustration placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.tertiarySystemGroupedBackground))
                        .frame(width: 160, height: 160)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
                .padding(.top, DesignTokens.Spacing.xl)

                // Title
                Text("Qyra Family Plan")
                    .font(.title.weight(.bold))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                // Features list
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    ForEach(features, id: \.text) { feature in
                        HStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(DesignTokens.Colors.accent)
                                .frame(width: 32)

                            Text(feature.text)
                                .font(.body)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                // Pricing
                Text("Only $2.50/mo more! ($59.99/yr)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .padding(.top, DesignTokens.Spacing.sm)

                // CTA Button
                Button {
                    // TODO: Implement upgrade flow
                } label: {
                    Text("Upgrade to Family Plan")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.Layout.buttonHeight)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)

                // Footer links
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Button("Terms") {}
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text("\u{00B7}")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)

                    Button("Privacy") {}
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text("\u{00B7}")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)

                    Button("Restore") {}
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .padding(.top, DesignTokens.Spacing.sm)
            }
            .frame(maxWidth: .infinity)
        }
        .background(DesignTokens.Colors.primaryBackground)
        .navigationTitle("Family Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        FamilyPlanView()
    }
}
