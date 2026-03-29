import SwiftUI

struct WeeklyDebrief: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let weekEndDate: Date
    let cards: [DebriefCard]
    let generatedAt: Date
}

struct DebriefCard: Identifiable {
    let id = UUID()
    let type: DebriefCardType
    let title: String
    let body: String
    let metric: String?
    let trend: Trend?
    let accentColor: Color
}

enum DebriefCardType {
    case adherence, bestDay, patternShift, macroSpotlight, weeklyFocus, streak
}

enum Trend {
    case up, down, flat

    var iconName: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
}
