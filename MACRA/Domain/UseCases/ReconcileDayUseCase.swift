import Foundation

struct ReconcileDayUseCase: Sendable {
    private let mealRepository: MealRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol

    init(mealRepository: MealRepositoryProtocol, goalRepository: GoalRepositoryProtocol) {
        self.mealRepository = mealRepository
        self.goalRepository = goalRepository
    }

    func execute(for date: Date) async throws -> DayReconciliation {
        async let summaryTask = mealRepository.fetchDailySummary(for: date)
        async let goalTask = goalRepository.fetchCurrentGoal()

        let summary = try await summaryTask
        let goal = try await goalTask ?? .default

        return DayReconciliation(summary: summary, goal: goal)
    }
}
