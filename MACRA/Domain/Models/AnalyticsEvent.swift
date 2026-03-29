import Foundation
import SwiftData

@Model
final class AnalyticsEvent {
    var id: UUID
    var name: String
    var properties: String // JSON-encoded dictionary
    var timestamp: Date
    var isSynced: Bool
    var sessionId: String
    var userId: String?

    init(
        name: String,
        properties: [String: String] = [:],
        sessionId: String,
        userId: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.properties = (try? JSONEncoder().encode(properties)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        self.timestamp = Date()
        self.isSynced = false
        self.sessionId = sessionId
        self.userId = userId
    }

    var decodedProperties: [String: String] {
        guard let data = properties.data(using: .utf8),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return dict
    }
}
