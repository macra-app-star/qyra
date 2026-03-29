import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Qyra AI
                NavigationLink {
                    MacroIntelligenceView()
                } label: {
                    insightCard(
                        icon: "brain.head.profile",
                        iconColor: DesignTokens.Colors.aiAccent,
                        title: "Qyra AI",
                        description: "Track your nutrition patterns and get AI insights"
                    )
                }
                .buttonStyle(.plain)

                // Progress
                NavigationLink {
                    ProgressTabView()
                } label: {
                    insightCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: DesignTokens.Colors.brandAccent,
                        title: "Progress",
                        description: "Track your weight, streaks, and body composition"
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func insightCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(DesignTokens.Typography.medium(22))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.Typography.semibold(18))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(description)
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.medium(14))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
