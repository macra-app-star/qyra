import XCTest
@testable import MACRA

// MARK: - Mock Repositories

struct MockMealRepository: MealRepositoryProtocol {
    var summaryToReturn: DailySummary = DailySummary(
        date: Date(),
        totalCalories: 800,
        totalProtein: 60,
        totalCarbs: 80,
        totalFat: 30,
        meals: [
            MealSummary(
                id: UUID(),
                mealType: .lunch,
                date: Date(),
                items: [
                    MealItemSummary(
                        id: UUID(),
                        foodName: "Chicken Breast",
                        calories: 300,
                        protein: 40,
                        carbs: 0,
                        fat: 8,
                        servingSize: "6 oz",
                        entryMethod: .manual
                    )
                ]
            )
        ]
    )
    var addMealCalled = false

    func fetchDailySummary(for date: Date) async throws -> DailySummary {
        summaryToReturn
    }

    func addMeal(date: Date, mealType: MealType, items: [NewMealItem]) async throws {}
    func deleteMeal(id: UUID) async throws {}
    func deleteMealItem(id: UUID) async throws {}
}

struct MockGoalRepository: GoalRepositoryProtocol {
    var goalToReturn: MacroGoalSnapshot? = .default

    func fetchCurrentGoal() async throws -> MacroGoalSnapshot? {
        goalToReturn
    }

    func saveGoal(_ goal: MacroGoalSnapshot) async throws {}
}

// MARK: - Tests

final class MACRATests: XCTestCase {

    func testMealSummaryTotals() {
        let items: [MealItemSummary] = [
            MealItemSummary(id: UUID(), foodName: "Rice", calories: 200, protein: 4, carbs: 45, fat: 1, servingSize: "1 cup", entryMethod: .manual),
            MealItemSummary(id: UUID(), foodName: "Chicken", calories: 300, protein: 40, carbs: 0, fat: 8, servingSize: nil, entryMethod: .manual),
        ]
        let meal = MealSummary(id: UUID(), mealType: .lunch, date: Date(), items: items)

        XCTAssertEqual(meal.totalCalories, 500)
        XCTAssertEqual(meal.totalProtein, 44)
        XCTAssertEqual(meal.totalCarbs, 45)
        XCTAssertEqual(meal.totalFat, 9)
        XCTAssertEqual(meal.displayDetail, "Rice, Chicken")
    }

    func testDefaultGoalValues() {
        let goal = MacroGoalSnapshot.default
        XCTAssertEqual(goal.dailyCalorieGoal, 2000)
        XCTAssertEqual(goal.dailyProteinGoal, 150)
        XCTAssertEqual(goal.dailyCarbGoal, 200)
        XCTAssertEqual(goal.dailyFatGoal, 65)
    }

    func testReconcileDayWithGoal() async throws {
        let mealRepo = MockMealRepository()
        let goalRepo = MockGoalRepository(goalToReturn: MacroGoalSnapshot(
            dailyCalorieGoal: 2500,
            dailyProteinGoal: 180,
            dailyCarbGoal: 250,
            dailyFatGoal: 80,
            activityLevel: .veryActive,
            goalType: .bulk
        ))

        let useCase = ReconcileDayUseCase(mealRepository: mealRepo, goalRepository: goalRepo)
        let result = try await useCase.execute(for: Date())

        XCTAssertEqual(result.summary.totalCalories, 800)
        XCTAssertEqual(result.goal.dailyCalorieGoal, 2500)
    }

    func testReconcileDayFallsBackToDefault() async throws {
        let mealRepo = MockMealRepository()
        let goalRepo = MockGoalRepository(goalToReturn: nil)

        let useCase = ReconcileDayUseCase(mealRepository: mealRepo, goalRepository: goalRepo)
        let result = try await useCase.execute(for: Date())

        XCTAssertEqual(result.goal, .default)
    }

    @MainActor
    func testDashboardViewModelLoads() async {
        let mealRepo = MockMealRepository()
        let goalRepo = MockGoalRepository()

        let useCase = ReconcileDayUseCase(mealRepository: mealRepo, goalRepository: goalRepo)
        let vm = DashboardViewModel(reconcileDay: useCase)

        await vm.loadDay()

        XCTAssertEqual(vm.currentCalories, 800)
        XCTAssertEqual(vm.currentProtein, 60)
        XCTAssertEqual(vm.calorieGoal, 2000)
        XCTAssertEqual(vm.proteinGoal, 150)
        XCTAssertEqual(vm.meals.count, 1)
        XCTAssertFalse(vm.isLoading)
    }

    @MainActor
    func testManualEntryCanSaveValidation() {
        let mealRepo = MockMealRepository()
        let vm = ManualEntryViewModel(mealRepository: mealRepo)

        XCTAssertFalse(vm.canSave)

        vm.foodName = "Test Food"
        XCTAssertFalse(vm.canSave)

        vm.caloriesText = "200"
        XCTAssertTrue(vm.canSave)

        vm.foodName = "   "
        XCTAssertFalse(vm.canSave)
    }
}
