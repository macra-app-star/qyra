import SwiftUI

@Observable @MainActor
final class MilestonesViewModel {
    var badges: [Badge] = []
    var totalXP: Int = 0
    var level: Int = 1
    var dayStreak: Int = 0

    var unlockedCount: Int {
        badges.filter(\.isUnlocked).count
    }

    var nextBadgeName: String {
        badges.first(where: { !$0.isUnlocked })?.name ?? "All earned!"
    }

    func loadBadges() {
        badges = Badge.allBadges
        // All start locked -- unlock logic is placeholder for future
        totalXP = badges.filter(\.isUnlocked).reduce(0) { $0 + $1.xpValue }
        level = max(1, totalXP / 100 + 1)
    }
}
