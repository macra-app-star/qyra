import SwiftUI

struct MilestonesView: View {
    @State var viewModel = MilestonesViewModel()

    var body: some View {
        List {
            // Hero section
            Section {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "flame.fill")
                            .font(.title)
                            .foregroundStyle(DesignTokens.Colors.streakOrange)

                        Text("\(viewModel.dayStreak)")
                            .font(DesignTokens.Typography.numeric(28))
                            .foregroundStyle(Color(.label))

                        Text("day streak")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))

                        Spacer()
                    }

                    HStack {
                        Text("\(viewModel.unlockedCount) Badges Earned")
                            .font(.headline)
                            .foregroundStyle(Color(.label))
                        Spacer()
                    }
                }
            }

            // Stats row
            Section {
                HStack {
                    VStack(spacing: 2) {
                        Text("\(viewModel.totalXP)")
                            .font(DesignTokens.Typography.numeric(20))
                            .foregroundStyle(Color(.label))
                        Text("Total XP")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack(spacing: 2) {
                        Text("\(viewModel.level)")
                            .font(DesignTokens.Typography.numeric(20))
                            .foregroundStyle(Color(.label))
                        Text("Level")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    VStack(spacing: 2) {
                        Text(viewModel.nextBadgeName)
                            .font(DesignTokens.Typography.numeric(20))
                            .foregroundStyle(Color(.label))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Text("Next Badge")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 4)
            }

            // Badge sections grouped by category
            ForEach(BadgeCategory.allCases) { category in
                let categoryBadges = viewModel.badges.filter { $0.category == category }
                if !categoryBadges.isEmpty {
                    Section(category.rawValue) {
                        ForEach(categoryBadges) { badge in
                            MilestoneRow(badge: badge)
                        }
                    }
                }
            }
        }
        .contentMargins(.bottom, 80)
        .listStyle(.insetGrouped)
        .navigationTitle("Milestones")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.loadBadges()
        }
    }
}

// MARK: - MilestoneRow

private struct MilestoneRow: View {
    let badge: Badge

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: badge.category.iconName)
                .font(.title3)
                .foregroundStyle(badge.isUnlocked ? Color.orange : Color(.tertiaryLabel))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(badge.name)
                    .font(.body)
                    .foregroundStyle(badge.isUnlocked ? Color(.label) : Color(.tertiaryLabel))

                Text(badge.description)
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            if badge.isUnlocked {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            } else {
                Image(systemName: "lock")
                    .font(.body)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        MilestonesView()
    }
}
