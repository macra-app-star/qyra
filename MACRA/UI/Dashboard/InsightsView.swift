import SwiftUI

struct InsightsView: View {
    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("Weekly Insights")
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Track your macro adherence and trends over time")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                // Streak placeholder
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("5 day streak")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
        }
        .navigationTitle("Insights")
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
}
