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

    private let reconcileDay: ReconcileDayUseCase

    convenience init(modelContainer: ModelContainer) {
        let mealRepo = MealRepository(modelContainer: modelContainer)
        let goalRepo = GoalRepository(modelContainer: modelContainer)
        self.init(
            reconcileDay: ReconcileDayUseCase(
                mealRepository: mealRepo,
                goalRepository: goalRepo
            )
        )
    }

    init(reconcileDay: ReconcileDayUseCase) {
        self.reconcileDay = reconcileDay
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
    }

    func refresh() async {
        await loadDay()
    }
}
