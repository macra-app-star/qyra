import SwiftUI

struct GroupLeaderboardView: View {
    let entries: [LeaderboardEntry]

    var body: some View {
        if entries.isEmpty {
            emptyState
        } else {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(entries) { entry in
                        leaderboardRow(entry)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
            }
        }
    }

    // MARK: - Leaderboard Row

    private func leaderboardRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Rank number
            Text("\(entry.rank)")
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(rankColor(for: entry.rank))
                .frame(width: 28)

            // Avatar
            let avatarColor = DesignTokens.Colors.avatarColors[entry.avatarColorIndex % DesignTokens.Colors.avatarColors.count]
            Text(entry.initials)
                .font(DesignTokens.Typography.semibold(14))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(avatarColor)
                .clipShape(Circle())

            // Name + subtitle
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(entry.name)
                    .font(DesignTokens.Typography.semibold(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("\(entry.score.formatted()) cal tracked")
                    .font(DesignTokens.Typography.bodyFont(12))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            // Score
            Text(entry.score.formatted())
                .font(DesignTokens.Typography.numeric(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(entry.isCurrentUser ? DesignTokens.Colors.surface : .clear)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return DesignTokens.Colors.leaderboardGold
        case 2: return DesignTokens.Colors.leaderboardSilver
        case 3: return DesignTokens.Colors.leaderboardBronze
        default: return DesignTokens.Colors.textSecondary
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            EmptyDataView(
                title: "No Leaderboard Data",
                subtitle: "Members need to log meals to appear in the rankings."
            )
            Spacer()
        }
    }
}

#Preview("With Entries") {
    GroupLeaderboardView(entries: LeaderboardEntry.sampleEntries)
        .background(DesignTokens.Colors.background)
}

#Preview("Empty") {
    GroupLeaderboardView(entries: [])
        .background(DesignTokens.Colors.background)
}
