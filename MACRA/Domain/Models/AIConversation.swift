import Foundation
import SwiftData

@Model
final class AIConversation {
    @Attribute(.unique) var id: UUID
    var userId: String
    var title: String
    var preview: String?
    var createdAt: Date
    var updatedAt: Date
    var messageCount: Int
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \AIConversationMessage.conversation)
    var messages: [AIConversationMessage]?

    init(
        id: UUID = UUID(),
        userId: String = "",
        title: String = "New conversation",
        preview: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        messageCount: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.preview = preview
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
        self.isArchived = isArchived
    }
}
