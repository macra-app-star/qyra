import SwiftUI
import SwiftData

struct TodayDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?
    @State private var showLogWater = false
    @State private var showLogCaffeine = false
    @State private var showNotifications = false

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Error banner
                    if let error = vm.errorMessage {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(DesignTokens.Typography.footnote)
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                            Spacer()
                            Button {
                                vm.errorMessage = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                            }
                        }
                        .padding(DesignTokens.Spacing.sm)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    // Header: apple emoji + Qyra, streak pill
                    headerRow(vm)

                    // Week calendar strip with expand chevron
                    HStack(spacing: 0) {
                        WeeklyDateStripView(
                            selectedDate: Binding(
                                get: { vm.selectedDate },
                                set: { newDate in
                                    vm.selectedDate = newDate
                                    Task { await vm.loadDay(newDate) }
                                }
                            ),
                            dayCalories: vm.weekCalories
                        )

                        // Chevron toggle for expanded calendar
                        Button {
                            vm.toggleCalendar()
                        } label: {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .rotationEffect(.degrees(vm.isCalendarExpanded ? 180 : 0))
                                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: vm.isCalendarExpanded)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, -DesignTokens.Spacing.md)

                    // Expanded monthly calendar
                    if vm.isCalendarExpanded {
                        ExpandedCalendarView(viewModel: vm)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // Paged card carousel + page indicator (grouped tight)
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        pagedCarousel(vm)

                        PageIndicatorView(
                            pageCount: 3,
                            currentPage: vm.currentPage
                        )
                    }

                    // Status pill — contextual day evaluation
                    dailyStatusPill(vm)

                    // Streak protection nudge (evening, no meals logged)
                    if vm.recentMeals.isEmpty && Calendar.current.component(.hour, from: Date()) >= 20 && vm.dayStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                            Text("Your \(vm.dayStreak)-day streak is at risk")
                                .font(.subheadline)
                            Spacer()
                            Button("Log now") {
                                // Opens scanner
                            }
                            .font(.caption.bold())
                            .foregroundStyle(Color.accentColor)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }

                    // AI Coach Insight Card
                    if let insight = vm.coachInsight {
                        NavigationLink(destination: IntelligenceDetailView()) {
                            coachInsightCard(insight)
                        }
                        .buttonStyle(.plain)
                    }

                    // Supplements & Compounds card
                    NavigationLink(destination: CompoundsDashboardView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "pills.fill")
                                .font(.title3)
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Supplements & Compounds")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                Text("Track your supplements, peptides, and medications")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(DesignTokens.Spacing.md)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DesignTokens.Layout.screenMargin)

                    // Fasting card
                    FastingCardView()
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)

                    // Today's workouts
                    todaysWorkoutsSection

                    // Recently uploaded section
                    RecentlyUploadedSection(
                        meals: vm.recentMeals,
                        mealSummaries: vm.mealSummaries,
                        modelContainer: modelContext.container,
                        onDelete: { mealId in
                            Task { await vm.deleteMeal(id: mealId) }
                        },
                        onRefresh: {
                            Task { await vm.refresh() }
                        },
                        onLogMeal: {
                            NotificationCenter.default.post(name: .openFoodScanner, object: nil)
                        }
                    )
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
        .navigationDestination(for: MealSummary.self) { summary in
            MealDetailView(
                meal: summary,
                modelContainer: modelContext.container,
                onDelete: {
                    Task { await viewModel?.refresh() }
                }
            )
        }
        .refreshable {
            await viewModel?.refresh()
        }
        .task {
            if viewModel == nil {
                let vm = TodayViewModel(modelContainer: modelContext.container)
                viewModel = vm
                await vm.initialLoad()
                await vm.fetchCoachInsight()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .mealLogged)) { _ in
            Task { await viewModel?.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .exerciseLogged)) { _ in
            Task { await viewModel?.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .waterLogged)) { _ in
            // Water is already updated locally in logWater(); no full refresh needed
        }
        .onReceive(NotificationCenter.default.publisher(for: .caffeineLogged)) { _ in
            // Caffeine is already updated locally in logCaffeine(); no full refresh needed
        }
        .onReceive(NotificationCenter.default.publisher(for: .appBecameActive)) { _ in
            Task { await viewModel?.refresh() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            Task { await viewModel?.refresh() }
        }
        .sheet(isPresented: $showLogWater) {
            if let vm = viewModel {
                LogWaterSheetView(viewModel: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showLogCaffeine) {
            if let vm = viewModel {
                LogCaffeineSheetView(viewModel: vm)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
    }

    // MARK: - Today's Workouts

    private var todaysWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Today's workouts")
                .font(.title3.bold())
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Layout.screenMargin)

            Text("No workouts yet today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DesignTokens.Layout.screenMargin)
        }
    }

    // MARK: - Daily Status Pill

    @ViewBuilder
    private func dailyStatusPill(_ vm: TodayViewModel) -> some View {
        let status = DailyStatus.evaluate(
            consumed: vm.caloriesConsumed,
            target: Double(vm.calorieTarget),
            protein: vm.proteinConsumed,
            proteinTarget: Double(vm.proteinTarget),
            mealsLogged: vm.recentMeals.count,
            hour: Calendar.current.component(.hour, from: Date())
        )

        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.caption)
                .foregroundStyle(status.color)
            Text(status.label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Header

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Good evening"
        }

        if let firstName = UserDefaults.standard.string(forKey: "firstName"), !firstName.isEmpty {
            return "\(timeGreeting), \(firstName)"
        }
        return timeGreeting
    }

    @ViewBuilder
    private func headerRow(_ vm: TodayViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Leading: brand name
                HStack(spacing: 0) {
                    Text("Qyra.")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(Color(.label))
                        .tracking(-0.8)

                    Text("®")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(.label))
                        .baselineOffset(14)
                }

                Spacer()

                // Notification bell
                Button { showNotifications = true } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(.label))
                }

                // Trailing: streak pill
                if vm.dayStreak > 0 {
                    streakPill(vm.dayStreak)
                }
            }

            // Personalized greeting
            Text(greetingText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, DesignTokens.Spacing.sm)
    }

    @ViewBuilder
    private func streakPill(_ streak: Int) -> some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(QyraFont.regular(14))
                .foregroundStyle(DesignTokens.Colors.streakOrange)

            Text("\(streak)")
                .font(DesignTokens.Typography.semibold(14))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .padding(.vertical, DesignTokens.Spacing.xs + 2)
        .background(DesignTokens.Colors.surface)
        .clipShape(Capsule())
    }

    // MARK: - Coach Insight Card

    private func coachInsightCard(_ insight: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.aiAccent.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkles")
                    .font(QyraFont.regular(16))
                    .foregroundStyle(DesignTokens.Colors.aiAccent)
            }

            Text("Qyra AI")
                .font(DesignTokens.Typography.semibold(15))
                .foregroundStyle(DesignTokens.Colors.aiAccent)

            Spacer()

            Image(systemName: "chevron.right")
                .font(QyraFont.regular(14))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
        .premiumCard(elevation: .subtle)
    }

    // MARK: - Paged Carousel

    private func pagedCarousel(_ vm: TodayViewModel) -> some View {
        CarouselPageView(
            pages: [
                AnyView(TodayMacrosPageView(viewModel: vm)),
                AnyView(TodayMicronutrientsPageView(viewModel: vm)),
                AnyView(TodayActivityPageView(viewModel: vm, onLogWater: { showLogWater = true }, onLogCaffeine: { showLogCaffeine = true }))
            ],
            currentPage: Binding(
                get: { vm.currentPage },
                set: { vm.currentPage = $0 }
            )
        )
        .frame(height: 380)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TodayDashboardView()
    }
    .modelContainer(for: [], inMemory: true)
}
