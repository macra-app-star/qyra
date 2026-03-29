import Foundation
import SwiftData

@Model
final class VersusChallenge {
    var id: UUID = UUID()
    var userId: String = ""
    var name: String = ""
    var metricRaw: String = VersusMetric.totalCaloriesBurned.rawValue
    var durationRaw: String = VersusDuration.sevenDays.rawValue
    var stakes: String = ""
    var opponentUsername: String = ""
    var createdAt: Date = Date()
    var startDate: Date = Date()
    var myScore: Double = 0
    var opponentScore: Double = 0

    var metric: VersusMetric {
        get { VersusMetric(rawValue: metricRaw) ?? .totalCaloriesBurned }
        set { metricRaw = newValue.rawValue }
    }

    var duration: VersusDuration {
        get { VersusDuration(rawValue: durationRaw) ?? .sevenDays }
        set { durationRaw = newValue.rawValue }
    }

    var endDate: Date {
        Calendar.current.date(byAdding: .day, value: duration.days, to: startDate) ?? startDate
    }

    var isActive: Bool { Date() < endDate }

    var daysRemaining: Int {
        max(0, Calendar.current.dateComponents([.day], from: .now, to: endDate).day ?? 0)
    }

    init(name: String, metric: VersusMetric, duration: VersusDuration, stakes: String = "", opponent: String = "") {
        self.name = name
        self.metricRaw = metric.rawValue
        self.durationRaw = duration.rawValue
        self.stakes = stakes
        self.opponentUsername = opponent
    }
}

enum VersusMetric: String, Codable, CaseIterable, Identifiable {
    case totalCaloriesBurned = "Calories Burned"
    case proteinConsumed = "Protein Consumed"
    case totalWorkouts = "Total Workouts"
    case workoutVolume = "Workout Volume"
    case steps = "Steps"
    case loggingStreak = "Logging Streak"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .totalCaloriesBurned: return "flame.fill"
        case .proteinConsumed: return "fork.knife"
        case .totalWorkouts: return "dumbbell.fill"
        case .workoutVolume: return "scalemass.fill"
        case .steps: return "figure.walk"
        case .loggingStreak: return "calendar.badge.checkmark"
        }
    }
}

enum VersusDuration: String, Codable, CaseIterable, Identifiable {
    case oneDay = "1 Day"
    case threeDays = "3 Days"
    case sevenDays = "7 Days"
    case fourteenDays = "14 Days"
    case thirtyDays = "30 Days"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .oneDay: return 1
        case .threeDays: return 3
        case .sevenDays: return 7
        case .fourteenDays: return 14
        case .thirtyDays: return 30
        }
    }
}
