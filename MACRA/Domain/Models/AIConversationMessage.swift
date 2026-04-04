import Foundation
import SwiftData

@Model
final class AIConversationMessage {
    @Attribute(.unique) var id: UUID
    var conversationId: UUID
    var userId: String
    var role: String
    var content: String
    var createdAt: Date

    var conversation: AIConversation?

    init(
        id: UUID = UUID(),
        conversationId: UUID,
        userId: String = "",
        role: String,
        content: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.conversationId = conversationId
        self.userId = userId
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}
