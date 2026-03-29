import Foundation
import SwiftData

@Model
final class CaffeineEntry {
    @Attribute(.unique) var id: UUID
    var userId: String
    var amountMg: Double
    var timestamp: Date
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        userId: String = "",
        amountMg: Double = 95.0,
        timestamp: Date = .now,
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.amountMg = amountMg
        self.timestamp = timestamp
        self.isSynced = isSynced
    }
}
