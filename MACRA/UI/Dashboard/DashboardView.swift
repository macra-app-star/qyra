import SwiftUI
import SwiftData

// MARK: - Health Score Info Sheet (inlined — not in Xcode target as separate file)
struct HealthScoreInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let factors: [(icon: String, title: String, weight: String, description: String)] = [
        ("target", "Calorie Goal Adherence", "40%", "How closely your daily intake matches your target."),
        ("chart.pie.fill", "Macro Balance", "30%", "The ratio of protein, carbs, and fat relative to your goals."),
        ("leaf.fill", "Micronutrient Completeness", "20%", "Coverage of essential vitamins and minerals."),
        ("calendar.badge.checkmark", "Meal Logging Consistency", "10%", "How regularly you log meals each day.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Your Health Score is a composite metric based on four factors:")
                        .font(DesignTokens.Typography.bodyFont(15))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    ForEach(factors, id: \.title) { factor in
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                            Image(systemName: factor.icon)
                                .font(DesignTokens.Typography.icon(20))
                                .foregroundStyle(DesignTokens.Colors.brandAccent)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(factor.title)
                                        .font(DesignTokens.Typography.semibold(15))
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    Spacer()
                                    Text(factor.weight)
                                        .font(DesignTokens.Typography.semibold(15))
                                        .foregroundStyle(DesignTokens.Colors.brandAccent)
                                }
                                Text(factor.description)
                                    .font(DesignTokens.Typography.bodyFont(13))
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                            }
                        }
                        .padding(DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }

                    Text("This is not a medical assessment. Consult a healthcare professional for medical advice.")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DesignTokens.Spacing.sm)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Health Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardViewModel?
    @State private var showManualEntry = false
    @State private var showCamera = false
    @State private var showBarcodeScanner = false
    @State private var showVoiceLog = false
    @State private var showFoodSearch = false
    @State private var showQuickAdd = false
    @State private var showHealthScoreInfo = false

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Day navigation header
                    dayNavigationBar(vm)

                    // Qyra title + profile
                    titleRow(vm)

                    // Weekly date strip
                    WeeklyDateStripView(
                        selectedDate: Binding(
                            get: { vm.selectedDate },
                            set: { newDate in
                                vm.selectedDate = newDate
                                Task { await vm.loadDay() }
                            }
                        )
                    )
                    .padding(.horizontal, -DesignTokens.Spacing.md)

                    // Combined calorie + macro card
                    calorieMacroCard(vm)

                    // AI Coach card
                    aiCoachCard(vm)

                    // What Should I Eat?
                    whatToEatCard(vm)

                    // Water + Exercise row
                    waterExerciseRow(vm)

                    // Fasting card
                    fastingCard(vm)

                    // Quick Log section
                    quickLogSection(vm)

                    // Recent Meals
                    recentMealsSection(vm)

                    // Weight Forecast
                    weightForecastCard

                    // Micronutrients
                    micronutrientSection(vm)

                    // Health Score
                    healthScoreCard(vm)

                    // Activity
                    activitySection(vm)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, 100)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationBarHidden(true)
        .refreshable {
            await viewModel?.refresh()
        }
        .task {
            if viewModel == nil {
                let vm = DashboardViewModel(modelContainer: modelContext.container)
                viewModel = vm
                await vm.initialLoad()
            }
        }
        .sheet(isPresented: $showManualEntry, onDismiss: {
            Task { await viewModel?.refresh() }
        }) {
            ManualEntryView(modelContainer: modelContext.container)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showCamera, onDismiss: {
            Task { await viewModel?.refresh() }
        }) {
            CameraView()
        }
        .sheet(isPresented: $showBarcodeScanner, onDismiss: {
            Task { await viewModel?.refresh() }
        }) {
            BarcodeScannerView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showVoiceLog, onDismiss: {
            Task { await viewModel?.refresh() }
        }) {
            VoiceLogView(modelContainer: modelContext.container)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showQuickAdd) {
            quickAddSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHealthScoreInfo) {
            HealthScoreInfoSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Day Navigation Bar

    private func dayNavigationBar(_ vm: DashboardViewModel) -> some View {
        HStack {
            Button {
                vm.selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: vm.selectedDate) ?? vm.selectedDate
                Task { await vm.loadDay() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(DesignTokens.Typography.medium(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            Spacer()

            Text(dayNavigationTitle(vm))
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            if Calendar.current.isDateInToday(vm.selectedDate) {
                // Show disabled forward when on today
                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.medium(16))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            } else {
                Button {
                    if Calendar.current.isDate(
                        Calendar.current.date(byAdding: .day, value: 1, to: vm.selectedDate) ?? vm.selectedDate,
                        inSameDayAs: Date()
                    ) {
                        vm.selectedDate = Date()
                    } else {
                        vm.selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: vm.selectedDate) ?? vm.selectedDate
                    }
                    Task { await vm.loadDay() }
                } label: {
                    Text("Today")
                        .font(DesignTokens.Typography.bodyFont(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Image(systemName: "chevron.right")
                        .font(DesignTokens.Typography.medium(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
            }
        }
        .padding(.top, DesignTokens.Spacing.sm)
    }

    private func dayNavigationTitle(_ vm: DashboardViewModel) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(vm.selectedDate) {
            return "Today"
        } else if cal.isDateInYesterday(vm.selectedDate) {
            return "Yesterday"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEEE, MMM d"
            return fmt.string(from: vm.selectedDate)
        }
    }

    // MARK: - Title Row

    private func titleRow(_ vm: DashboardViewModel) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text("Qyra.")
                    .font(DesignTokens.Typography.headlineFont(28))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(vm.greeting)
                    .font(DesignTokens.Typography.bodyFont(16))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "person.circle")
                .font(DesignTokens.Typography.light(32))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Combined Calorie + Macro Card

    private func calorieMacroCard(_ vm: DashboardViewModel) -> some View {
        let progress = vm.calorieGoal > 0 ? min(vm.currentCalories / vm.calorieGoal, 1.0) : 0
        let remaining = max(vm.calorieGoal - vm.currentCalories, 0)

        return VStack(spacing: DesignTokens.Spacing.lg) {
            // Top: Calorie display + ring
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("\(Int(vm.hasAnimated ? vm.currentCalories : 0).formatted())")
                        .font(DesignTokens.Typography.numeric(44))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .contentTransition(.numericText())

                    Text("cal eaten")
                        .font(DesignTokens.Typography.bodyFont(15))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text("\(Int(remaining)) remaining · \(Int(vm.calorieGoal).formatted()) goal")
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                Spacer()

                // Calorie Ring
                ZStack {
                    Circle()
                        .stroke(DesignTokens.Colors.ringTrack, style: StrokeStyle(lineWidth: 10, lineCap: .round))

                    Circle()
                        .trim(from: 0, to: vm.hasAnimated ? progress : 0)
                        .stroke(DesignTokens.Colors.brandAccent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(DesignTokens.Anim.ring, value: progress)

                    VStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(DesignTokens.Typography.icon(14))
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                        Text("\(Int(vm.hasAnimated ? vm.currentCalories : 0).formatted())")
                            .font(DesignTokens.Typography.numeric(16))
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                    }
                }
                .frame(width: 90, height: 90)
            }

            // Divider
            Rectangle()
                .fill(DesignTokens.Colors.border.opacity(0.5))
                .frame(height: 0.5)
                .padding(.horizontal, -DesignTokens.Spacing.sm)

            // Bottom: Macro bars
            HStack(spacing: DesignTokens.Spacing.lg) {
                macroColumn(
                    value: Int(vm.hasAnimated ? vm.currentProtein : 0),
                    goal: Int(vm.proteinGoal),
                    label: "Protein",
                    color: DesignTokens.Colors.protein
                )

                macroColumn(
                    value: Int(vm.hasAnimated ? vm.currentCarbs : 0),
                    goal: Int(vm.carbGoal),
                    label: "Carbs",
                    color: DesignTokens.Colors.carbs
                )

                macroColumn(
                    value: Int(vm.hasAnimated ? vm.currentFat : 0),
                    goal: Int(vm.fatGoal),
                    label: "Fat",
                    color: DesignTokens.Colors.fat
                )
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private func macroColumn(value: Int, goal: Int, label: String, color: Color) -> some View {
        let progress = goal > 0 ? min(Double(value) / Double(goal), 1.0) : 0

        return VStack(spacing: DesignTokens.Spacing.xs) {
            // Value
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("\(value)")
                    .font(DesignTokens.Typography.numeric(20))
                    .foregroundStyle(color)
                Text("g")
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // Label
            Text(label)
                .font(DesignTokens.Typography.medium(12))
                .foregroundStyle(color)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.Colors.ringTrack)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(DesignTokens.Anim.ring, value: progress)
                }
            }
            .frame(height: 4)

            // Goal
            Text("/\(goal)g")
                .font(DesignTokens.Typography.bodyFont(11))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - AI Coach Card

    private func aiCoachCard(_ vm: DashboardViewModel) -> some View {
        NavigationLink {
            AICoachDetailView(vm: vm)
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        // Sparkle icon
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.aiAccent.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: "sparkles")
                                .font(DesignTokens.Typography.medium(16))
                                .foregroundStyle(DesignTokens.Colors.aiAccent)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("AI COACH")
                                .font(DesignTokens.Typography.headlineFont(11))
                                .foregroundStyle(DesignTokens.Colors.aiAccent)
                            Text(vm.coachHeadline)
                                .font(DesignTokens.Typography.semibold(16))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                        }
                    }

                    Text(vm.coachMessage)
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)

                    if !vm.coachTip.isEmpty {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Text("💡")
                                .font(DesignTokens.Typography.icon(12))
                            Text(vm.coachTip)
                                .font(DesignTokens.Typography.bodyFont(13))
                                .foregroundStyle(DesignTokens.Colors.brandAccent)
                        }
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.aiCoachBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - What Should I Eat?

    private func whatToEatCard(_ vm: DashboardViewModel) -> some View {
        let remaining = max(vm.calorieGoal - vm.currentCalories, 0)

        return NavigationLink {
            WhatToEatView(
                remainingCalories: remaining,
                remainingProtein: max(vm.proteinGoal - vm.currentProtein, 0),
                remainingCarbs: max(vm.carbGoal - vm.currentCarbs, 0),
                remainingFat: max(vm.fatGoal - vm.currentFat, 0)
            )
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.brandAccent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "magnifyingglass")
                        .font(DesignTokens.Typography.medium(18))
                        .foregroundStyle(DesignTokens.Colors.brandAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("What Should I Eat?")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("\(Int(remaining)) cal remaining — get AI suggestions")
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Water + Exercise Row

    private func waterExerciseRow(_ vm: DashboardViewModel) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            // Water
            NavigationLink {
                WaterDetailView()
            } label: {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "drop.fill")
                        .font(DesignTokens.Typography.icon(22))
                        .foregroundStyle(DesignTokens.Colors.water)

                    Text("\(vm.waterOunces) oz")
                        .font(DesignTokens.Typography.numeric(20))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("of \(vm.waterGoal) oz")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text("Water")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.lg)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
            }
            .buttonStyle(.plain)

            // Exercise
            NavigationLink {
                ExerciseLogView()
            } label: {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "figure.run")
                        .font(DesignTokens.Typography.icon(22))
                        .foregroundStyle(DesignTokens.Colors.protein)

                    Text("\(vm.activeCalories) cal")
                        .font(DesignTokens.Typography.numeric(20))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("\(vm.workoutCount) workouts")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text("Exercise")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.lg)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Fasting Card

    private func fastingCard(_ vm: DashboardViewModel) -> some View {
        NavigationLink {
            FastingSetupView()
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.fasting.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "timer")
                        .font(DesignTokens.Typography.medium(20))
                        .foregroundStyle(DesignTokens.Colors.fasting)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Fasting: \(vm.fastingDisplay)")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("\(vm.fastingRemaining) remaining · \(vm.fastingSchedule)")
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Log Section

    private func quickLogSection(_ vm: DashboardViewModel) -> some View {
        Group {
            if !vm.meals.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(DesignTokens.Typography.medium(15))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("Quick Log")
                            .font(DesignTokens.Typography.semibold(17))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Text("Tap to re-log")
                            .font(DesignTokens.Typography.bodyFont(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            ForEach(vm.meals) { meal in
                                quickLogCard(meal: meal)
                            }
                        }
                    }
                }
            }
        }
    }

    private func quickLogCard(meal: MealSummary) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: meal.mealType.icon)
                    .font(DesignTokens.Typography.icon(12))
                    .foregroundStyle(mealTypeColor(meal.mealType))
                Text(meal.mealType.displayName)
                    .font(DesignTokens.Typography.bodyFont(12))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Text(meal.displayDetail)
                .font(DesignTokens.Typography.semibold(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(Int(meal.totalCalories)) cal  \(Int(meal.totalProtein))g P")
                .font(DesignTokens.Typography.bodyFont(12))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Button {
                showManualEntry = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignTokens.Typography.icon(14))
                    Text("Log Again")
                        .font(DesignTokens.Typography.medium(13))
                }
                .foregroundStyle(DesignTokens.Colors.protein)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(width: 200, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Recent Meals Section

    private func recentMealsSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Recent Meals")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if vm.meals.isEmpty {
                emptyMealsCard
            } else {
                ForEach(vm.meals) { meal in
                    mealRow(meal: meal, vm: vm)
                }
            }
        }
    }

    private var emptyMealsCard: some View {
        EmptyDataView(
            title: "No Meals Logged",
            subtitle: "Snap a photo, scan a barcode, or search for what you ate.",
            actionTitle: "Log a Meal",
            action: { showManualEntry = true }
        )
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private func mealRow(meal: MealSummary, vm: DashboardViewModel) -> some View {
        NavigationLink {
            MealDetailView(meal: meal, modelContainer: modelContext.container) {
                Task { await vm.refresh() }
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Meal icon in tinted circle
                ZStack {
                    Circle()
                        .fill(mealTypeColor(meal.mealType).opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: meal.mealType.icon)
                        .font(DesignTokens.Typography.icon(16))
                        .foregroundStyle(mealTypeColor(meal.mealType))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(meal.mealType.displayName)
                            .font(DesignTokens.Typography.semibold(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Text(mealTimeString(meal.date))
                            .font(DesignTokens.Typography.bodyFont(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    Text(meal.displayDetail)
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    // Macro chips
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        macroChip("\(Int(meal.totalCalories)) cal", color: DesignTokens.Colors.textPrimary, bg: DesignTokens.Colors.textPrimary.opacity(0.08))
                        macroChip("\(Int(meal.totalProtein))g P", color: DesignTokens.Colors.protein, bg: DesignTokens.Colors.protein.opacity(0.0))
                        macroChip("\(Int(meal.totalCarbs))g C", color: DesignTokens.Colors.carbs, bg: DesignTokens.Colors.carbs.opacity(0.0))
                        macroChip("\(Int(meal.totalFat))g F", color: DesignTokens.Colors.fat, bg: DesignTokens.Colors.fat.opacity(0.0))
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                Task { await vm.deleteMeal(id: meal.id) }
            } label: {
                Label("Delete Meal", systemImage: "trash")
            }
        }
    }

    private func macroChip(_ text: String, color: Color, bg: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.medium(11))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    // MARK: - Weight Forecast

    private var weightForecastCard: some View {
        NavigationLink {
            WeightForecastView()
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.aiAccent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(DesignTokens.Typography.medium(18))
                        .foregroundStyle(DesignTokens.Colors.aiAccent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight Forecast")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("See your projected weight trajectory")
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Micronutrients

    private func micronutrientSection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Micronutrients")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                microCard(
                    icon: "leaf.fill",
                    iconColor: DesignTokens.Colors.fiber,
                    label: "Fiber",
                    value: "0",
                    unit: "g",
                    remaining: "38g left"
                )
                microCard(
                    icon: "drop.fill",
                    iconColor: DesignTokens.Colors.sugar,
                    label: "Sugar",
                    value: "0",
                    unit: "g",
                    remaining: "94g left"
                )
                microCard(
                    icon: "sparkles",
                    iconColor: DesignTokens.Colors.sodium,
                    label: "Sodium",
                    value: "0",
                    unit: "mg",
                    remaining: "2,300mg left"
                )
            }
        }
    }

    private func microCard(icon: String, iconColor: Color, label: String, value: String, unit: String, remaining: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.ringTrack, lineWidth: 3)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(DesignTokens.Typography.icon(18))
                    .foregroundStyle(iconColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(DesignTokens.Typography.numeric(18))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(unit)
                    .font(DesignTokens.Typography.bodyFont(11))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Text(label)
                .font(DesignTokens.Typography.medium(12))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(remaining)
                .font(DesignTokens.Typography.bodyFont(11))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Health Score

    private func healthScoreCard(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(DesignTokens.Typography.icon(18))
                    .foregroundStyle(DesignTokens.Colors.healthScoreAccent)

                Text("Health Score")
                    .font(DesignTokens.Typography.semibold(17))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Button {
                    showHealthScoreInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(DesignTokens.Typography.icon(16))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(vm.healthScore)")
                        .font(DesignTokens.Typography.numeric(28))
                        .foregroundStyle(DesignTokens.Colors.healthScoreAccent)
                    Text("/10")
                        .font(DesignTokens.Typography.bodyFont(15))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.ringTrack)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.healthScoreAccent)
                        .frame(width: geo.size.width * (Double(vm.healthScore) / 10.0), height: 8)
                }
            }
            .frame(height: 8)

            Text(vm.healthScoreMessage)
                .font(DesignTokens.Typography.bodyFont(14))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.healthScoreBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    // MARK: - Activity

    private func activitySection(_ vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Activity")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                activityTile(
                    icon: "figure.walk",
                    label: "Steps",
                    value: vm.steps > 0 ? vm.steps.formatted() : "\u{2014}",
                    color: DesignTokens.Colors.textPrimary
                )
                activityTile(
                    icon: "flame.fill",
                    label: "Active",
                    value: vm.activeCalories > 0 ? "\(vm.activeCalories) cal" : "\u{2014} cal",
                    color: DesignTokens.Colors.textPrimary
                )
            }
        }
    }

    private func activityTile(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(DesignTokens.Typography.icon(18))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DesignTokens.Typography.headlineFont(17))
                    .foregroundStyle(color)
                Text(label)
                    .font(DesignTokens.Typography.bodyFont(12))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Quick Add Sheet

    private var quickAddSheet: some View {
        let columns = [
            GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
            GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
            GridItem(.flexible(), spacing: DesignTokens.Spacing.md)
        ]

        return VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Log Something")
                .font(DesignTokens.Typography.title2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(.top, DesignTokens.Spacing.lg)

            LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                quickAddItem(icon: "camera.fill", label: "Camera", color: DesignTokens.Colors.protein) {
                    showQuickAdd = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showCamera = true }
                }
                quickAddItem(icon: "mic.fill", label: "Voice", color: DesignTokens.Colors.brandAccent) {
                    showQuickAdd = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showVoiceLog = true }
                }
                quickAddItem(icon: "barcode.viewfinder", label: "Barcode", color: DesignTokens.Colors.fasting) {
                    showQuickAdd = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showBarcodeScanner = true }
                }
                quickAddItem(icon: "pencil", label: "Manual", color: DesignTokens.Colors.textPrimary) {
                    showQuickAdd = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showManualEntry = true }
                }
                quickAddItem(icon: "figure.run", label: "Exercise", color: DesignTokens.Colors.aiAccent) {
                    showQuickAdd = false
                }
                quickAddItem(icon: "drop.fill", label: "Water", color: DesignTokens.Colors.fat) {
                    showQuickAdd = false
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer()
        }
        .background(DesignTokens.Colors.background)
    }

    private func quickAddItem(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(DesignTokens.Typography.icon(28))
                    .foregroundStyle(color)
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 90)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Helpers

    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return DesignTokens.Colors.fasting
        case .lunch: return DesignTokens.Colors.healthScoreAccent
        case .dinner: return DesignTokens.Colors.aiAccent
        case .snack: return DesignTokens.Colors.brandAccent
        }
    }

    private func mealTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.default, value: configuration.isPressed)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self, UserProfile.self])
}
