import Foundation
import SwiftData

// MARK: - Preview Support

extension OnboardingViewModel {
    /// A lightweight preview instance that uses an in-memory model container
    /// and a stub goal repository. Safe to use in SwiftUI previews.
    @MainActor
    static var preview: OnboardingViewModel {
        let schema = Schema([
            MealLog.self,
            MealItem.self,
            MacroGoal.self,
            UserProfile.self,
            SyncRecord.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        return OnboardingViewModel(
            goalRepository: PreviewGoalRepository(),
            modelContainer: container
        )
    }
}

// MARK: - Stub Repository

private struct PreviewGoalRepository: GoalRepositoryProtocol {
    func fetchCurrentGoal() async throws -> MacroGoalSnapshot? { nil }
    func saveGoal(_ goal: MacroGoalSnapshot) async throws { }
}
