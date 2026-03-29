import SwiftUI

struct RhythmInsightCard: View {
    let insight: RhythmAnalyzer.RhythmInsight

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            // Icon
            Image(systemName: insight.icon)
                .font(DesignTokens.Typography.icon(20))
                .foregroundStyle(DesignTokens.Colors.aiAccent)
                .frame(width: 36, height: 36)
                .background(DesignTokens.Colors.aiAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            // Text content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(insight.title)
                    .font(DesignTokens.Typography.semibold(14))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(insight.body)
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .premiumCard()
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        RhythmInsightCard(
            insight: RhythmAnalyzer.RhythmInsight(
                type: .mealTiming,
                title: "Evening-heavy pattern",
                body: "You tend to consume most calories after 6 PM. Shifting some intake earlier can improve energy and sleep quality.",
                icon: "moon.stars.fill",
                priority: 5
            )
        )
        RhythmInsightCard(
            insight: RhythmAnalyzer.RhythmInsight(
                type: .proteinPacing,
                title: "Spread your protein",
                body: "Over half your daily protein is in one meal. Distributing it across meals supports better muscle synthesis.",
                icon: "chart.bar.fill",
                priority: 4
            )
        )
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
