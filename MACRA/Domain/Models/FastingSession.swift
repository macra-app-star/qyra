import Foundation
import SwiftData

@Model
final class FastingSession {
    var id: UUID = UUID()
    var userId: String = ""
    var scheduleRaw: String = FastingSchedule.sixteenEight.rawValue
    var startTime: Date = Date()
    var targetDuration: TimeInterval = 16 * 3600
    var endTime: Date?
    var createdAt: Date = Date()

    var schedule: FastingSchedule {
        get { FastingSchedule(rawValue: scheduleRaw) ?? .sixteenEight }
        set { scheduleRaw = newValue.rawValue }
    }

    var isActive: Bool { endTime == nil && Date() < startTime.addingTimeInterval(targetDuration) }
    var isCompleted: Bool { endTime != nil || Date() >= startTime.addingTimeInterval(targetDuration) }

    var elapsed: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var remaining: TimeInterval {
        max(0, targetDuration - elapsed)
    }

    var progress: Double {
        min(1.0, elapsed / targetDuration)
    }

    init(schedule: FastingSchedule, startTime: Date = Date()) {
        self.scheduleRaw = schedule.rawValue
        self.startTime = startTime
        self.targetDuration = TimeInterval(schedule.fastingHours) * 3600
    }
}

enum FastingSchedule: String, Codable, CaseIterable, Identifiable {
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "20:4"
    case twentyFourHour = "24 Hour"
    case custom = "Custom"

    var id: String { rawValue }

    var fastingHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .twentyFourHour: return 24
        case .custom: return 16
        }
    }

    var eatingHours: Int { 24 - fastingHours }

    var subtitle: String? {
        switch self {
        case .sixteenEight: return "Most popular"
        case .eighteenSix: return nil
        case .twentyFour: return nil
        case .twentyFourHour: return "Full day fast"
        case .custom: return "Set your own hours"
        }
    }
}
