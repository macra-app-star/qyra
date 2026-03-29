import Foundation
import SwiftData

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var userId: String
    var weightLbs: Double
    var timestamp: Date
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        userId: String = "",
        weightLbs: Double = 0,
        timestamp: Date = .now,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.weightLbs = weightLbs
        self.timestamp = timestamp
        self.isSynced = isSynced
    }
}
