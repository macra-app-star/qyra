import Foundation

protocol GoalRepositoryProtocol: Sendable {
    func fetchCurrentGoal() async throws -> MacroGoalSnapshot?
    func saveGoal(_ goal: MacroGoalSnapshot) async throws
}
