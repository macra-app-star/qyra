import Foundation
import SwiftData

@Model
final class WaterEntry {
    @Attribute(.unique) var id: UUID
    var userId: String
    var amountOz: Double
    var timestamp: Date
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        userId: String = "",
        amountOz: Double = 8.0,
        timestamp: Date = .now,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.amountOz = amountOz
        self.timestamp = timestamp
        self.isSynced = isSynced
    }
}
