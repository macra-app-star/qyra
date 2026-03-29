import Foundation
import SwiftData

enum ExerciseSource: String, Codable {
    case manual
    case ai
    case healthkit
}

@Model
final class ExerciseEntry {
    @Attribute(.unique) var id: UUID
    var userId: String
    var exerciseType: String // ExerciseType rawValue
    var name: String
    var durationMinutes: Int
    var caloriesBurned: Double
    var intensity: Double // 0.0 - 1.0
    var source: ExerciseSource
    var timestamp: Date
    var notes: String?
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        userId: String = "",
        exerciseType: String = ExerciseType.run.rawValue,
        name: String = "",
        durationMinutes: Int = 30,
        caloriesBurned: Double = 0,
        intensity: Double = 0.5,
        source: ExerciseSource = .manual,
        timestamp: Date = .now,
        notes: String? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.exerciseType = exerciseType
        self.name = name
        self.durationMinutes = durationMinutes
        self.caloriesBurned = caloriesBurned
        self.intensity = intensity
        self.source = source
        self.timestamp = timestamp
        self.notes = notes
        self.isSynced = isSynced
    }

    var resolvedExerciseType: ExerciseType? {
        ExerciseType(rawValue: exerciseType)
    }
}
