import Foundation
import SwiftData

@Observable
@MainActor
final class GoalEditorViewModel {
    var calorieText = ""
    var proteinText = ""
    var carbText = ""
    var fatText = ""
    var activityLevel: ActivityLevel = .moderatelyActive
    var goalType: GoalType = .maintain
    var didSave = false
    var isLoading = true

    private let goalRepository: GoalRepositoryProtocol

    convenience init(modelContainer: ModelContainer) {
        self.init(goalRepository: GoalRepository(modelContainer: modelContainer))
    }

    init(goalRepository: GoalRepositoryProtocol) {
        self.goalRepository = goalRepository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let goal = (try? await goalRepository.fetchCurrentGoal()) ?? .default
        calorieText = "\(goal.dailyCalorieGoal)"
        proteinText = "\(goal.dailyProteinGoal)"
        carbText = "\(goal.dailyCarbGoal)"
        fatText = "\(goal.dailyFatGoal)"
        activityLevel = goal.activityLevel
        goalType = goal.goalType
    }

    var canSave: Bool {
        (Int(calorieText) ?? 0) > 0
    }

    func save() async {
        guard canSave else { return }

        let snapshot = MacroGoalSnapshot(
            dailyCalorieGoal: Int(calorieText) ?? 2000,
            dailyProteinGoal: Int(proteinText) ?? 150,
            dailyCarbGoal: Int(carbText) ?? 200,
            dailyFatGoal: Int(fatText) ?? 65,
            activityLevel: activityLevel,
            goalType: goalType
        )

        try? await goalRepository.saveGoal(snapshot)
        didSave = true
    }
}
