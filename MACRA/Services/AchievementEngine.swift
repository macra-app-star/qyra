import Foundation
import SwiftData
import os

/// Detects and unlocks achievements based on user activity metrics.
@MainActor
final class AchievementEngine: ObservableObject {

    static let shared = AchievementEngine()

    @Published var pendingCelebration: AchievementDefinition?
    @Published var unlockedCount: Int = 0

    private var modelContainer: ModelContainer?
    private let logger = Logger(subsystem: "co.tamras.qyra", category: "Achievements")

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Check all achievements against current metrics. Call after meal logged, workout completed, etc.
    func evaluate(metrics: [String: Int]) {
        guard let container = modelContainer else { return }
        let userId = CurrentUserProvider.shared.requiredUserId

        Task.detached(priority: .utility) {
            let context = ModelContext(container)

            // Get already unlocked achievement IDs
            let descriptor = FetchDescriptor<UnlockedAchievement>(
                predicate: #Predicate { $0.userId == userId }
            )
            let existing = (try? context.fetch(descriptor)) ?? []
            let existingIds = Set(existing.map(\.achievementId))

            var newUnlocks: [AchievementDefinition] = []

            for achievement in AchievementDefinition.all {
                // Skip if already unlocked
                guard !existingIds.contains(achievement.id) else { continue }

                // Check if threshold is met
                let currentValue = metrics[achievement.metricKey] ?? 0
                if currentValue >= achievement.threshold {
                    let unlock = UnlockedAchievement(
                        achievementId: achievement.id,
                        userId: userId
                    )
                    context.insert(unlock)
                    newUnlocks.append(achievement)
                }
            }

            if !newUnlocks.isEmpty {
                try? context.save()

                // Celebrate the highest-rarity new unlock
                let best = newUnlocks.max(by: { $0.rarity < $1.rarity })
                let finalUnlocks = newUnlocks

                await MainActor.run { [weak self] in
                    self?.unlockedCount = existingIds.count + finalUnlocks.count
                    if let best {
                        self?.pendingCelebration = best
                        self?.logger.info("Achievement unlocked: \(best.title) (\(best.rarity.rawValue))")
                    }
                }
            } else {
                await MainActor.run { [weak self] in
                    self?.unlockedCount = existingIds.count
                }
            }
        }
    }

    /// Build metrics dictionary from current data. Call this to get fresh counts.
    func buildMetrics(from container: ModelContainer, userId: String) async -> [String: Int] {
        let context = ModelContext(container)
        var metrics: [String: Int] = [:]

        // Meals logged
        let mealsDesc = FetchDescriptor<MealLog>(predicate: #Predicate { $0.userId == userId })
        metrics["meals_logged"] = (try? context.fetchCount(mealsDesc)) ?? 0

        // Exercises logged
        let exerciseDesc = FetchDescriptor<ExerciseEntry>(predicate: #Predicate { $0.userId == userId })
        metrics["workouts_logged"] = (try? context.fetchCount(exerciseDesc)) ?? 0

        // Weight entries
        let weightDesc = FetchDescriptor<WeightEntry>(predicate: #Predicate { $0.userId == userId })
        metrics["weight_entries"] = (try? context.fetchCount(weightDesc)) ?? 0

        // Streak days (from UserDefaults for now)
        metrics["streak_days"] = UserDefaults.standard.integer(forKey: "currentStreak")

        // Scan/barcode counts (from analytics or UserDefaults)
        metrics["scans_completed"] = UserDefaults.standard.integer(forKey: "total_scans")
        metrics["barcodes_scanned"] = UserDefaults.standard.integer(forKey: "total_barcodes")

        // Social
        let groupDesc = FetchDescriptor<GroupModel>(predicate: #Predicate { $0.userId == userId })
        metrics["groups_joined"] = (try? context.fetchCount(groupDesc)) ?? 0

        let versusDesc = FetchDescriptor<VersusChallenge>(predicate: #Predicate { $0.userId == userId })
        metrics["versus_created"] = (try? context.fetchCount(versusDesc)) ?? 0

        // Fasting
        let fastingDesc = FetchDescriptor<FastingSession>(predicate: #Predicate { $0.userId == userId && $0.endTime != nil })
        metrics["fasts_completed"] = (try? context.fetchCount(fastingDesc)) ?? 0

        // Compounds
        let compoundDesc = FetchDescriptor<CompoundEntry>(predicate: #Predicate { $0.userId == userId })
        metrics["compounds_logged"] = (try? context.fetchCount(compoundDesc)) ?? 0

        return metrics
    }

    /// Dismiss the celebration overlay
    func dismissCelebration() {
        pendingCelebration = nil
    }
}
