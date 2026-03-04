import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showManualEntry = false
    @State private var showComingSoon = false
    @State private var comingSoonFeature = ""

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    headerSection

                    macroRingsSection(vm)

                    NutritionCardComponent(
                        calories: vm.currentCalories,
                        protein: vm.currentProtein,
                        carbs: vm.currentCarbs,
                        fat: vm.currentFat
                    )

                    quickActionsSection

                    recentMealsSection(vm)

                    healthSummarySection(vm)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    changeDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if !Calendar.current.isDateInToday(viewModel?.selectedDate ?? Date()) {
                        Button("Today") {
                            viewModel?.selectedDate = Date()
                            Task { await viewModel?.loadDay() }
                        }
                        .font(DesignTokens.Typography.caption)
                    }
                    Button {
                        changeDate(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .disabled(Calendar.current.isDateInToday(viewModel?.selectedDate ?? Date()))
                }
            }
        }
        .task {
            if viewModel == nil {
                let vm = DashboardViewModel(modelContainer: modelContext.container)
                viewModel = vm
                await vm.loadDay()
            }
        }
        .sheet(isPresented: $showManualEntry, onDismiss: {
            Task {
                await viewModel?.refresh()
            }
        }) {
            ManualEntryView(modelContainer: modelContext.container)
        }
        .alert(comingSoonFeature, isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comingSoonFeature) is coming in a future update.")
        }
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

    private func macroRingsSection(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            MacroRingComponent(
                label: "Calories",
                current: vm.currentCalories,
                goal: vm.calorieGoal,
                unit: "cal",
                ringColor: DesignTokens.Colors.ringCalories,
                lineWidth: 10
            )

            MacroRingComponent(
                label: "Protein",
                current: vm.currentProtein,
                goal: vm.proteinGoal,
                unit: "g",
                ringColor: DesignTokens.Colors.ringProtein
            )

            MacroRingComponent(
                label: "Carbs",
                current: vm.currentCarbs,
                goal: vm.carbGoal,
                unit: "g",
                ringColor: DesignTokens.Colors.ringCarbs
            )

            MacroRingComponent(
                label: "Fat",
                current: vm.currentFat,
                goal: vm.fatGoal,
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
                quickActionTile(icon: "barcode.viewfinder", label: "Barcode") {
                    comingSoonFeature = "Barcode scanning"
                    showComingSoon = true
                }
                quickActionTile(icon: "camera.fill", label: "Camera") {
                    comingSoonFeature = "Camera scanning"
                    showComingSoon = true
                }
                quickActionTile(icon: "mic.fill", label: "Voice") {
                    comingSoonFeature = "Voice logging"
                    showComingSoon = true
                }
                quickActionTile(icon: "pencil", label: "Manual") {
                    showManualEntry = true
                }
            }
        }
    }

    private func quickActionTile(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            DesignTokens.Haptics.light()
            action()
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

    private func recentMealsSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Recent Meals")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if vm.meals.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 28))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                        Text("No meals logged yet")
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    Spacer()
                }
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            } else {
                ForEach(vm.meals) { meal in
                    NavigationLink {
                        MealDetailView(meal: meal) {
                            Task { await vm.refresh() }
                        }
                    } label: {
                        HStack {
                            Image(systemName: meal.mealType.icon)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(meal.mealType.displayName)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                Text(meal.displayDetail)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(Int(meal.totalCalories)) cal")
                                .font(DesignTokens.Typography.subheadline)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                        .padding(DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func healthSummarySection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Activity")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                healthTile(icon: "figure.walk", label: "Steps", value: vm.steps > 0 ? "\(vm.steps)" : "—")
                healthTile(icon: "flame.fill", label: "Active", value: vm.activeCalories > 0 ? "\(vm.activeCalories) cal" : "— cal")
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

    private var navigationTitle: String {
        guard let date = viewModel?.selectedDate else { return "Today" }
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: viewModel?.selectedDate ?? Date())
    }

    private func changeDate(by days: Int) {
        guard let vm = viewModel,
              let newDate = Calendar.current.date(byAdding: .day, value: days, to: vm.selectedDate) else { return }
        guard newDate <= Date() else { return }
        vm.selectedDate = newDate
        Task { await vm.loadDay() }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
