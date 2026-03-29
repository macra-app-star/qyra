import Foundation
import SwiftData

@Model
final class ProgressPhoto {
    @Attribute(.unique) var id: UUID
    var userId: String = ""
    @Attribute(.externalStorage) var imageData: Data
    var timestamp: Date
    var note: String?

    init(imageData: Data, timestamp: Date = Date(), note: String? = nil) {
        self.id = UUID()
        self.imageData = imageData
        self.timestamp = timestamp
        self.note = note
    }
}
