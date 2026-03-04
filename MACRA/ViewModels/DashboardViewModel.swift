import Foundation
import SwiftData

@Observable
@MainActor
final class DashboardViewModel {
    var currentCalories: Double = 0
    var currentProtein: Double = 0
    var currentCarbs: Double = 0
    var currentFat: Double = 0

    var calorieGoal: Double = 2000
    var proteinGoal: Double = 150
    var carbGoal: Double = 200
    var fatGoal: Double = 65

    var meals: [MealSummary] = []
    var isLoading = false
    var selectedDate = Date()

    var steps: Int = 0
    var activeCalories: Int = 0

    var displayName: String = ""
    var hasAnimated: Bool = false

    private let reconcileDay: ReconcileDayUseCase
    private let healthKit = HealthKitService.shared
    private var modelContainer: ModelContainer?
    private var hasRequestedHealthKit = false

    convenience init(modelContainer: ModelContainer) {
        let mealRepo = MealRepository(modelContainer: modelContainer)
        let goalRepo = GoalRepository(modelContainer: modelContainer)
        self.init(
            reconcileDay: ReconcileDayUseCase(
                mealRepository: mealRepo,
                goalRepository: goalRepo
            )
        )
        self.modelContainer = modelContainer
    }

    init(reconcileDay: ReconcileDayUseCase) {
        self.reconcileDay = reconcileDay
    }

    func initialLoad() async {
        await loadDisplayName()
        await requestHealthKitIfNeeded()
        await loadDay()

        try? await Task.sleep(for: .milliseconds(100))
        hasAnimated = true
    }

    func loadDay() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await reconcileDay.execute(for: selectedDate)

            currentCalories = result.summary.totalCalories
            currentProtein = result.summary.totalProtein
            currentCarbs = result.summary.totalCarbs
            currentFat = result.summary.totalFat

            calorieGoal = Double(result.goal.dailyCalorieGoal)
            proteinGoal = Double(result.goal.dailyProteinGoal)
            carbGoal = Double(result.goal.dailyCarbGoal)
            fatGoal = Double(result.goal.dailyFatGoal)

            meals = result.summary.meals
        } catch {
            // Keep existing values on error
        }

        steps = await healthKit.steps(for: selectedDate)
        activeCalories = await healthKit.activeCalories(for: selectedDate)
    }

    func refresh() async {
        await loadDay()
    }

    func deleteMeal(id: UUID) async {
        guard let container = modelContainer else { return }
        let repo = MealRepository(modelContainer: container)
        try? await repo.deleteMeal(id: id)
        DesignTokens.Haptics.medium()
        await loadDay()
    }

    // MARK: - Private

    private func loadDisplayName() async {
        guard let container = modelContainer else { return }
        let profileRepo = ProfileRepository(modelContainer: container)
        displayName = (try? await profileRepo.fetchDisplayName()) ?? ""
    }

    private func requestHealthKitIfNeeded() async {
        guard !hasRequestedHealthKit, healthKit.isAvailable else { return }
        hasRequestedHealthKit = true
        _ = await healthKit.requestAuthorization()
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Good night"
        }
        if displayName.isEmpty {
            return timeGreeting
        }
        return "\(timeGreeting), \(displayName)"
    }
}
