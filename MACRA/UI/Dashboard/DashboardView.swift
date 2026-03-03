import SwiftUI

struct DashboardView: View {
    // Phase 3: Replace with @State private var viewModel = DashboardViewModel()
    // Mock data from existing export: 2000cal / 150P / 200C / 65F goals
    private let calorieGoal: Double = 2000
    private let proteinGoal: Double = 150
    private let carbGoal: Double = 200
    private let fatGoal: Double = 65

    // Simulated current values
    private let currentCalories: Double = 1450
    private let currentProtein: Double = 95
    private let currentCarbs: Double = 160
    private let currentFat: Double = 40

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Header
                headerSection

                // Macro Rings
                macroRingsSection

                // Nutrition Summary Card
                NutritionCardComponent(
                    calories: currentCalories,
                    protein: currentProtein,
                    carbs: currentCarbs,
                    fat: currentFat
                )

                // Quick Actions
                quickActionsSection

                // Recent Meals (stub)
                recentMealsSection

                // HealthKit Summary (stub for Phase 9)
                healthSummarySection
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(dateString)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "person.circle.fill")
                .font(.system(size: 32))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    private var macroRingsSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            MacroRingComponent(
                label: "Calories",
                current: currentCalories,
                goal: calorieGoal,
                unit: "cal",
                ringColor: DesignTokens.Colors.ringCalories,
                lineWidth: 10
            )

            MacroRingComponent(
                label: "Protein",
                current: currentProtein,
                goal: proteinGoal,
                unit: "g",
                ringColor: DesignTokens.Colors.ringProtein
            )

            MacroRingComponent(
                label: "Carbs",
                current: currentCarbs,
                goal: carbGoal,
                unit: "g",
                ringColor: DesignTokens.Colors.ringCarbs
            )

            MacroRingComponent(
                label: "Fat",
                current: currentFat,
                goal: fatGoal,
                unit: "g",
                ringColor: DesignTokens.Colors.ringFat
            )
        }
        .frame(height: 120)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Quick Add")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                quickActionTile(icon: "barcode.viewfinder", label: "Barcode")
                quickActionTile(icon: "camera.fill", label: "Camera")
                quickActionTile(icon: "mic.fill", label: "Voice")
                quickActionTile(icon: "pencil", label: "Manual")
            }
        }
    }

    private func quickActionTile(icon: String, label: String) -> some View {
        Button {
            DesignTokens.Haptics.light()
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private var recentMealsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Recent Meals")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ForEach(sampleMeals, id: \.name) { meal in
                HStack {
                    Image(systemName: meal.icon)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(meal.name)
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text(meal.detail)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }

                    Spacer()

                    Text("\(meal.calories) cal")
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            }
        }
    }

    private var healthSummarySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Activity")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                healthTile(icon: "figure.walk", label: "Steps", value: "8,432")
                healthTile(icon: "flame.fill", label: "Active", value: "340 cal")
            }
        }
    }

    private func healthTile(icon: String, label: String, value: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }

    // MARK: - Helpers

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var sampleMeals: [(name: String, detail: String, calories: Int, icon: String)] {
        [
            (name: "Breakfast", detail: "Greek Yogurt, Granola", calories: 380, icon: "sunrise.fill"),
            (name: "Lunch", detail: "Chicken Breast, Rice, Broccoli", calories: 620, icon: "sun.max.fill"),
            (name: "Snack", detail: "Quest Protein Bar", calories: 200, icon: "leaf.fill"),
        ]
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
}
