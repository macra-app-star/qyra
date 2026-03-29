import Foundation
import SwiftUI
import SwiftData

// MARK: - Achievement Definitions (static registry)

enum AchievementCategory: String, CaseIterable, Codable {
    case streak, nutrition, workout, scanner, body, social, explorer

    var displayName: String {
        switch self {
        case .streak: return "Streak Mastery"
        case .nutrition: return "Nutrition Logging"
        case .workout: return "Workout Warrior"
        case .scanner: return "Scanner Pro"
        case .body: return "Body Tracking"
        case .social: return "Social & Competition"
        case .explorer: return "Explorer"
        }
    }

    var tintColor: Color {
        switch self {
        case .streak: return .orange
        case .nutrition: return .green
        case .workout: return .accentColor
        case .scanner: return .purple
        case .body: return .cyan
        case .social: return .yellow
        case .explorer: return .indigo
        }
    }
}

enum AchievementRarity: String, Codable, Comparable {
    case common, uncommon, rare, epic, legendary

    static func < (lhs: AchievementRarity, rhs: AchievementRarity) -> Bool {
        let order: [AchievementRarity] = [.common, .uncommon, .rare, .epic, .legendary]
        return (order.firstIndex(of: lhs) ?? 0) < (order.firstIndex(of: rhs) ?? 0)
    }
}

struct AchievementDefinition: Identifiable, Equatable {
    let id: String
    let category: AchievementCategory
    let title: String
    let tagline: String
    let icon: String
    let threshold: Int
    let metricKey: String
    let rarity: AchievementRarity

    static let all: [AchievementDefinition] = [
        // Streak
        .init(id: "streak_3", category: .streak, title: "Spark", tagline: "Three days strong.", icon: "flame", threshold: 3, metricKey: "streak_days", rarity: .common),
        .init(id: "streak_7", category: .streak, title: "Ember", tagline: "A full week. Habit forming.", icon: "flame.fill", threshold: 7, metricKey: "streak_days", rarity: .common),
        .init(id: "streak_14", category: .streak, title: "Flame", tagline: "Two weeks. Not going back.", icon: "flame.fill", threshold: 14, metricKey: "streak_days", rarity: .uncommon),
        .init(id: "streak_30", category: .streak, title: "Blaze", tagline: "A full month. Changed.", icon: "flame.fill", threshold: 30, metricKey: "streak_days", rarity: .uncommon),
        .init(id: "streak_100", category: .streak, title: "Inferno", tagline: "Triple digits. Unstoppable.", icon: "flame.circle.fill", threshold: 100, metricKey: "streak_days", rarity: .rare),
        .init(id: "streak_365", category: .streak, title: "Eternal", tagline: "One year. Legend.", icon: "flame.circle.fill", threshold: 365, metricKey: "streak_days", rarity: .legendary),

        // Nutrition
        .init(id: "meals_1", category: .nutrition, title: "First Bite", tagline: "Your journey starts here.", icon: "fork.knife", threshold: 1, metricKey: "meals_logged", rarity: .common),
        .init(id: "meals_10", category: .nutrition, title: "Getting Started", tagline: "Double digits.", icon: "fork.knife", threshold: 10, metricKey: "meals_logged", rarity: .common),
        .init(id: "meals_50", category: .nutrition, title: "Nutrition Nerd", tagline: "50 meals tracked.", icon: "fork.knife.circle", threshold: 50, metricKey: "meals_logged", rarity: .uncommon),
        .init(id: "meals_100", category: .nutrition, title: "The Logfather", tagline: "100 meals. Machine.", icon: "fork.knife.circle.fill", threshold: 100, metricKey: "meals_logged", rarity: .rare),
        .init(id: "meals_500", category: .nutrition, title: "Macro Machine", tagline: "500 meals logged.", icon: "fork.knife.circle.fill", threshold: 500, metricKey: "meals_logged", rarity: .epic),

        // Workout
        .init(id: "workouts_1", category: .workout, title: "First Rep", tagline: "You showed up.", icon: "figure.strengthtraining.traditional", threshold: 1, metricKey: "workouts_logged", rarity: .common),
        .init(id: "workouts_10", category: .workout, title: "Gym Regular", tagline: "10 sessions deep.", icon: "dumbbell.fill", threshold: 10, metricKey: "workouts_logged", rarity: .common),
        .init(id: "workouts_50", category: .workout, title: "Iron Will", tagline: "50 workouts. Disciplined.", icon: "dumbbell.fill", threshold: 50, metricKey: "workouts_logged", rarity: .uncommon),
        .init(id: "workouts_100", category: .workout, title: "Beast Mode", tagline: "100 sessions. Beast.", icon: "figure.strengthtraining.functional", threshold: 100, metricKey: "workouts_logged", rarity: .rare),

        // Scanner
        .init(id: "scans_1", category: .scanner, title: "First Scan", tagline: "AI-powered nutrition.", icon: "camera.fill", threshold: 1, metricKey: "scans_completed", rarity: .common),
        .init(id: "scans_25", category: .scanner, title: "Scanner Pro", tagline: "25 scans. Quick draw.", icon: "camera.viewfinder", threshold: 25, metricKey: "scans_completed", rarity: .uncommon),
        .init(id: "scans_100", category: .scanner, title: "Macro Vision", tagline: "100 scans. X-ray eyes.", icon: "camera.aperture", threshold: 100, metricKey: "scans_completed", rarity: .rare),
        .init(id: "barcodes_10", category: .scanner, title: "Barcode Hunter", tagline: "10 barcodes scanned.", icon: "barcode.viewfinder", threshold: 10, metricKey: "barcodes_scanned", rarity: .common),

        // Body
        .init(id: "weight_1", category: .body, title: "Weigh In", tagline: "First weight logged.", icon: "scalemass.fill", threshold: 1, metricKey: "weight_entries", rarity: .common),
        .init(id: "weight_30", category: .body, title: "Body Tracker", tagline: "30 weigh-ins.", icon: "scalemass.fill", threshold: 30, metricKey: "weight_entries", rarity: .uncommon),
        .init(id: "water_7", category: .body, title: "Hydrated", tagline: "7 days of water logging.", icon: "drop.fill", threshold: 7, metricKey: "water_days", rarity: .common),

        // Social
        .init(id: "group_1", category: .social, title: "Team Player", tagline: "Joined your first group.", icon: "person.2.fill", threshold: 1, metricKey: "groups_joined", rarity: .common),
        .init(id: "challenge_1", category: .social, title: "Challenger", tagline: "Created your first challenge.", icon: "bolt.fill", threshold: 1, metricKey: "challenges_created", rarity: .common),
        .init(id: "versus_1", category: .social, title: "Rival", tagline: "Started a VERSUS.", icon: "bolt.circle.fill", threshold: 1, metricKey: "versus_created", rarity: .common),

        // Explorer
        .init(id: "fasting_1", category: .explorer, title: "Faster", tagline: "Completed your first fast.", icon: "timer", threshold: 1, metricKey: "fasts_completed", rarity: .common),
        .init(id: "compound_1", category: .explorer, title: "Biohacker", tagline: "Logged your first supplement.", icon: "pills.fill", threshold: 1, metricKey: "compounds_logged", rarity: .common),
        .init(id: "protein_goal_7", category: .explorer, title: "Protein King", tagline: "Hit protein goal 7 days.", icon: "trophy.fill", threshold: 7, metricKey: "protein_goal_days", rarity: .uncommon),
        .init(id: "calorie_goal_7", category: .explorer, title: "On Target", tagline: "Hit calorie goal 7 days.", icon: "target", threshold: 7, metricKey: "calorie_goal_days", rarity: .uncommon),
    ]
}

// MARK: - Unlocked Achievement (SwiftData persistence)

@Model
final class UnlockedAchievement {
    var id: UUID = UUID()
    var achievementId: String = ""
    var userId: String = ""
    var unlockedAt: Date = Date()
    var hasSeen: Bool = false

    init(achievementId: String, userId: String) {
        self.achievementId = achievementId
        self.userId = userId
        self.unlockedAt = .now
        self.hasSeen = false
    }
}
