import SwiftUI

struct SocialView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Spacer()
                    .frame(height: DesignTokens.Spacing.xxl)

                Image(systemName: "person.2.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Social is Coming Soon")
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("Connect with friends, join challenges, and climb the leaderboard together.")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Spacing.xl)
                }

                VStack(spacing: DesignTokens.Spacing.sm) {
                    featurePreview(icon: "trophy.fill", title: "Leaderboards", description: "Compete with friends on weekly macro goals")
                    featurePreview(icon: "figure.2.arms.open", title: "Challenges", description: "Join group challenges and stay motivated")
                    featurePreview(icon: "chart.bar.xaxis", title: "Comparisons", description: "See how your nutrition stacks up")
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Social")
    }

    private func featurePreview(icon: String, title: String, description: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}

#Preview {
    NavigationStack {
        SocialView()
    }
}
