import Foundation

enum ExerciseType: String, CaseIterable, Identifiable {
    case run
    case weightLifting
    case describe
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .run: return "Run"
        case .weightLifting: return "Weight Lifting"
        case .describe: return "Describe"
        case .manual: return "Manual"
        }
    }

    var subtitle: String {
        switch self {
        case .run: return "Track a run with intensity"
        case .weightLifting: return "Log weight training session"
        case .describe: return "Describe your exercise with AI"
        case .manual: return "Enter calories directly"
        }
    }

    var iconName: String {
        switch self {
        case .run: return "figure.run"
        case .weightLifting: return "dumbbell.fill"
        case .describe: return "text.bubble.fill"
        case .manual: return "flame.fill"
        }
    }

    var intensityLevels: [IntensityLevel] {
        switch self {
        case .run: return IntensityLevel.runLevels
        case .weightLifting: return IntensityLevel.weightLevels
        default: return []
        }
    }
}

struct IntensityLevel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let metValue: Double

    static func == (lhs: IntensityLevel, rhs: IntensityLevel) -> Bool {
        lhs.id == rhs.id
    }

    static let runLevels: [IntensityLevel] = [
        .init(name: "Walk", description: "Casual pace, easy breathing", metValue: 3.5),
        .init(name: "Jog", description: "Moderate pace, can hold conversation", metValue: 7.0),
        .init(name: "Run", description: "Brisk pace, harder to talk", metValue: 9.8),
        .init(name: "Sprint", description: "Near max effort, short bursts", metValue: 14.0),
        .init(name: "Hill Sprint", description: "Maximum intensity uphill", metValue: 16.0),
    ]

    static let weightLevels: [IntensityLevel] = [
        .init(name: "Light", description: "Easy weight, high reps", metValue: 3.5),
        .init(name: "Moderate", description: "Medium weight, steady pace", metValue: 5.0),
        .init(name: "Intense", description: "Heavy weight, challenging sets", metValue: 6.0),
        .init(name: "Very Intense", description: "Near max weight, low reps", metValue: 8.0),
        .init(name: "Max Effort", description: "Maximum weight, failure sets", metValue: 10.0),
    ]
}
