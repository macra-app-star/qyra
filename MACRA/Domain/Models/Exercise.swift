import Foundation
import SwiftData

// INTEGRATED FROM: ExerciseDB, Free Exercise DB, wrkout/exercises.json
// Searchable database of exercises with muscle targeting, equipment, and instructions.

@Model
final class Exercise {
    @Attribute(.unique) var externalId: String
    var name: String
    var bodyPart: String
    var targetMuscle: String
    var secondaryMuscles: [String]
    var equipment: String
    var instructions: [String]
    var gifURL: String?
    var metValue: Double
    var source: String
    var isFavorite: Bool
    var searchName: String

    init(
        externalId: String,
        name: String,
        bodyPart: String = "",
        targetMuscle: String = "",
        secondaryMuscles: [String] = [],
        equipment: String = "body weight",
        instructions: [String] = [],
        gifURL: String? = nil,
        metValue: Double = 5.0,
        source: String = "exercisedb",
        isFavorite: Bool = false
    ) {
        self.externalId = externalId
        self.name = name
        self.bodyPart = bodyPart
        self.targetMuscle = targetMuscle
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.gifURL = gifURL
        self.metValue = metValue
        self.source = source
        self.isFavorite = isFavorite
        self.searchName = name.lowercased()
    }
}

// MARK: - Body Part Categories

enum BodyPartCategory: String, CaseIterable, Identifiable {
    case back, cardio, chest, lowerArms = "lower arms", lowerLegs = "lower legs"
    case neck, shoulders, upperArms = "upper arms", upperLegs = "upper legs", waist

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .back: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .chest: return "figure.arms.open"
        case .lowerArms: return "hand.raised.fill"
        case .lowerLegs: return "figure.walk"
        case .neck: return "person.fill"
        case .shoulders: return "figure.flexibility"
        case .upperArms: return "dumbbell.fill"
        case .upperLegs: return "figure.run"
        case .waist: return "figure.core.training"
        }
    }
}
