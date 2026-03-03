import Foundation
import SwiftData

@ModelActor
actor GoalRepository: GoalRepositoryProtocol {

    func fetchCurrentGoal() async throws -> MacroGoalSnapshot? {
        var descriptor = FetchDescriptor<MacroGoal>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let goal = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return MacroGoalSnapshot(
            dailyCalorieGoal: goal.dailyCalorieGoal,
            dailyProteinGoal: goal.dailyProteinGoal,
            dailyCarbGoal: goal.dailyCarbGoal,
            dailyFatGoal: goal.dailyFatGoal,
            activityLevel: goal.activityLevel,
            goalType: goal.goalType
        )
    }

    func saveGoal(_ snapshot: MacroGoalSnapshot) async throws {
        var descriptor = FetchDescriptor<MacroGoal>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        let goal: MacroGoal
        if let existing = try modelContext.fetch(descriptor).first {
            goal = existing
        } else {
            goal = MacroGoal()
            modelContext.insert(goal)
        }

        goal.dailyCalorieGoal = snapshot.dailyCalorieGoal
        goal.dailyProteinGoal = snapshot.dailyProteinGoal
        goal.dailyCarbGoal = snapshot.dailyCarbGoal
        goal.dailyFatGoal = snapshot.dailyFatGoal
        goal.activityLevel = snapshot.activityLevel
        goal.goalType = snapshot.goalType
        goal.updatedAt = .now

        let syncRecord = SyncRecord(
            entityType: "MacroGoal",
            entityId: goal.id,
            operation: .update
        )
        modelContext.insert(syncRecord)

        try modelContext.save()
    }
}
