import SwiftUI

struct DailyAverageCaloriesSection: View {
    @Binding var filter: String

    private let filters = ["This wk", "Last wk", "2 wk ago", "3 wk ago"]

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Daily Average Calories")
                .font(DesignTokens.Typography.headlineFont(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            TimeFilterPills(options: filters, selection: $filter)

            // Stacked bar chart placeholder
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.surface)
                .frame(height: 180)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("Start your streak")
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text("Log meals consistently to unlock weekly insights")
                            .font(DesignTokens.Typography.footnote)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)

                        // Legend
                        HStack(spacing: DesignTokens.Spacing.md) {
                            legendDot(color: DesignTokens.Colors.protein, label: "Protein")
                            legendDot(color: DesignTokens.Colors.carbs, label: "Carbs")
                            legendDot(color: DesignTokens.Colors.fat, label: "Fat")
                        }
                    }
                )
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: DesignTokens.Layout.microGap) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(DesignTokens.Typography.bodyFont(11))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }
}

#Preview {
    @Previewable @State var filter = "This wk"
    DailyAverageCaloriesSection(filter: $filter)
        .padding()
        .background(DesignTokens.Colors.background)
}
