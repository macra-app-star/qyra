import SwiftUI
import SwiftData

struct InsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: InsightsViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Streak
                    streakCard(vm)

                    // Weekly bar chart
                    weeklyChartSection(vm)

                    // Averages
                    averagesSection(vm)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            } else {
                ProgressView()
                    .padding(.top, 100)
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Insights")
        .task {
            if viewModel == nil {
                let vm = InsightsViewModel(modelContainer: modelContext.container)
                viewModel = vm
                await vm.loadWeek()
            }
        }
    }

    // MARK: - Streak

    private func streakCard(_ vm: InsightsViewModel) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "flame.fill")
                .font(.system(size: 28))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(vm.streakDays) day streak")
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text("Keep hitting your targets!")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Chart

    private func weeklyChartSection(_ vm: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("This Week")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
                ForEach(vm.weekData) { day in
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        // Bar
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor(for: day))
                            .frame(height: barHeight(for: day))

                        Text(day.dayLabel)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 160)
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private func barHeight(for day: DayData) -> CGFloat {
        let maxHeight: CGFloat = 120
        guard day.calorieGoal > 0 else { return 4 }
        let ratio = day.calories / day.calorieGoal
        return max(4, min(maxHeight, CGFloat(ratio) * maxHeight))
    }

    private func barColor(for day: DayData) -> Color {
        if day.calories == 0 {
            return DesignTokens.Colors.ringTrack
        }
        let pct = day.adherencePercent
        if pct >= 80 && pct <= 120 {
            return DesignTokens.Colors.textPrimary
        }
        return DesignTokens.Colors.textTertiary
    }

    // MARK: - Averages

    private func averagesSection(_ vm: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Weekly Averages")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                averageTile(label: "Calories", value: "\(vm.weeklyAvgCalories)", unit: "cal")
                averageTile(label: "Protein", value: "\(vm.weeklyAvgProtein)", unit: "g")
            }
        }
    }

    private func averageTile(label: String, value: String, unit: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(value)
                .font(DesignTokens.Typography.monoSmall)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text("\(label) (\(unit))")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
