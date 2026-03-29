import SwiftUI

struct WeightForecastView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Weight Status
                weightStatusCard

                // Weight Trajectory
                trajectorySection

                // Pace + Avg Calories
                HStack(spacing: DesignTokens.Spacing.sm) {
                    statCard(title: "Weekly Pace", value: "—", subtitle: "lbs/week")
                    statCard(title: "Avg Calories", value: "—", subtitle: "cal/day")
                }

                // How This Works
                howItWorksSection

                // Disclaimer
                Text("Weight forecasts are estimates based on calorie intake and expenditure. Individual results may vary based on metabolism, activity level, and other factors.")
                    .font(DesignTokens.Typography.bodyFont(12))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Weight Forecast")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Weight Status

    private var weightStatusCard: some View {
        EmptyDataView(
            title: "No Weight Logged",
            subtitle: "Log your weight in Settings to see your forecast."
        )
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    // MARK: - Trajectory

    private var trajectorySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Weight Trajectory")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.surface)
                .frame(height: 160)
                .overlay(
                    EmptyDataView(
                        title: "Not Enough Data",
                        subtitle: "Track for a few more days to see your trajectory."
                    )
                )
        }
    }

    // MARK: - Stat Card

    private func statCard(title: String, value: String, subtitle: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text(value)
                .font(DesignTokens.Typography.numeric(28))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(subtitle)
                .font(DesignTokens.Typography.bodyFont(12))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - How This Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("How This Works")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            howItWorksRow(
                icon: "chart.bar.fill",
                title: "Daily Calorie Average",
                description: "We calculate your average daily calorie intake from your logged meals."
            )

            howItWorksRow(
                icon: "flame.fill",
                title: "Estimated TDEE",
                description: "Your Total Daily Energy Expenditure is estimated from your profile data."
            )

            howItWorksRow(
                icon: "plusminus",
                title: "Daily Balance",
                description: "The difference between intake and expenditure determines weight change."
            )
        }
    }

    private func howItWorksRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.aiAccent.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(DesignTokens.Colors.aiAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.semibold(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(description)
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}
