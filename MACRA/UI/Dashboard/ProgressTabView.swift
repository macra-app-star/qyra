import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProgressViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    StreakBadgesSection(
                        streak: vm.dayStreak,
                        badges: vm.badgesEarned
                    )

                    WeightCardSection(
                        current: vm.currentWeight,
                        start: vm.startWeight,
                        goal: vm.goalWeight,
                        progress: vm.weightProgress,
                        formattedCurrent: vm.formattedCurrentWeight,
                        formattedStart: vm.formattedStartWeight,
                        formattedGoal: vm.formattedGoalWeight,
                        estimatedDate: vm.formattedGoalDate
                    )

                    WeightChartSection(
                        weightEntries: vm.weightEntries,
                        currentWeight: vm.currentWeight,
                        filter: Binding(
                            get: { vm.weightChartFilter },
                            set: { vm.weightChartFilter = $0 }
                        )
                    )

                    WeightChangesSection(changes: vm.weightChanges)

                    ProgressPhotosSection()

                    DailyAverageCaloriesSection(filter: Binding(
                        get: { vm.caloriesWeekFilter },
                        set: { vm.caloriesWeekFilter = $0 }
                    ))

                    WeeklyEnergySection(
                        data: vm.weeklyEnergyData,
                        burned: vm.weeklyBurned,
                        consumed: vm.weeklyConsumed,
                        netEnergy: vm.weeklyNetEnergy,
                        filter: Binding(
                            get: { vm.energyWeekFilter },
                            set: { vm.energyWeekFilter = $0 }
                        )
                    )

                    ExpenditureChangesSection(changes: vm.expenditureChanges)

                    BMICardSection(
                        bmi: vm.bmi,
                        formattedBMI: vm.formattedBMI,
                        category: vm.bmiCategory
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
        .refreshable {
            if let vm = viewModel {
                await vm.initialLoad()
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .onReceive(NotificationCenter.default.publisher(for: .weightLogged)) { _ in
            Task { await viewModel?.initialLoad() }
        }
        .task {
            if viewModel == nil {
                let vm = ProgressViewModel(modelContainer: modelContext.container)
                viewModel = vm
                await vm.initialLoad()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProgressTabView()
    }
    .modelContainer(for: [], inMemory: true)
}
