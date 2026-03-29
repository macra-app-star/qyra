import SwiftUI

struct StreakBadgesSection: View {
    let streak: Int
    let badges: Int

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Streak Card
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .font(DesignTokens.Typography.icon(28))
                    .foregroundStyle(Color.orange)

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text("\(streak)")
                        .font(DesignTokens.Typography.numeric(24))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("Day Streak")
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    // Weekly dots
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(0..<7, id: \.self) { index in
                            Circle()
                                .fill(index < streak % 7 ? DesignTokens.Colors.brandAccent : DesignTokens.Colors.ringTrack)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

            // Badges Card - tappable link to Milestones
            NavigationLink {
                MilestonesView()
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "trophy.fill")
                        .font(DesignTokens.Typography.icon(28))
                        .foregroundStyle(DesignTokens.Colors.brandAccent)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("\(badges)")
                            .font(DesignTokens.Typography.numeric(24))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text("Badges Earned")
                            .font(DesignTokens.Typography.bodyFont(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(DesignTokens.Typography.icon(14))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Layout.cardGap) {
        StreakBadgesSection(streak: 0, badges: 0)
        StreakBadgesSection(streak: 5, badges: 3)
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
