import Foundation
import SwiftData

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case lightlyActive = "lightly_active"
    case moderatelyActive = "moderately_active"
    case veryActive = "very_active"
    case extremelyActive = "extremely_active"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .lightlyActive: return "Lightly Active"
        case .moderatelyActive: return "Moderately Active"
        case .veryActive: return "Very Active"
        case .extremelyActive: return "Extremely Active"
        }
    }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case cut
    case maintain
    case bulk

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

@Model
final class MacroGoal {
    @Attribute(.unique) var id: UUID
    var userId: String
    var dailyCalorieGoal: Int
    var dailyProteinGoal: Int
    var dailyCarbGoal: Int
    var dailyFatGoal: Int
    var activityLevel: ActivityLevel
    var goalType: GoalType
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: String = "",
        dailyCalorieGoal: Int = 2000,
        dailyProteinGoal: Int = 150,
        dailyCarbGoal: Int = 200,
        dailyFatGoal: Int = 65,
        activityLevel: ActivityLevel = .moderatelyActive,
        goalType: GoalType = .maintain
    ) {
        self.id = id
        self.userId = userId
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyProteinGoal = dailyProteinGoal
        self.dailyCarbGoal = dailyCarbGoal
        self.dailyFatGoal = dailyFatGoal
        self.activityLevel = activityLevel
        self.goalType = goalType
        self.createdAt = .now
        self.updatedAt = .now
    }
}
