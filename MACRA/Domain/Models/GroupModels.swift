import SwiftUI
import SwiftData
import UIKit

// MARK: - SwiftData Group Model

@Model
final class GroupModel {
    @Attribute(.unique) var id: UUID
    var userId: String = ""
    var name: String
    var inviteCode: String
    var isPrivate: Bool
    var createdAt: Date
    var memberCount: Int
    var remoteId: String

    init(name: String, isPrivate: Bool = true, inviteCode: String? = nil, remoteId: String = "") {
        self.id = UUID()
        self.name = name
        self.inviteCode = inviteCode ?? String(UUID().uuidString.prefix(6)).uppercased()
        self.isPrivate = isPrivate
        self.createdAt = Date()
        self.memberCount = 1
        self.remoteId = remoteId
    }
}

// MARK: - Group Info (Legacy display model)

struct GroupInfo: Identifiable {
    let id: UUID
    let name: String
    let memberCount: Int
    let iconEmoji: String  // SF Symbol name
}

// MARK: - Group Message

struct GroupMessage: Identifiable {
    let id: UUID
    let senderName: String
    let senderInitials: String
    let avatarColorIndex: Int  // index into DesignTokens.Colors.avatarColors
    let profilePhoto: UIImage?  // nil for other users, set for current user
    let text: String
    let timestamp: Date
    let replyTo: String?  // nil or the text being replied to
    let reactions: [GroupReaction]

    static let sampleMessages: [GroupMessage] = [
        GroupMessage(
            id: UUID(),
            senderName: "Sarah M.",
            senderInitials: "SM",
            avatarColorIndex: 0,
            profilePhoto: nil,
            text: "Just hit my protein goal for the first time this week!",
            timestamp: Date().addingTimeInterval(-3600),
            replyTo: nil,
            reactions: [
                GroupReaction(emoji: "\u{1F525}", count: 3, isSelected: false),
                GroupReaction(emoji: "\u{1F4AA}", count: 2, isSelected: true),
            ]
        ),
        GroupMessage(
            id: UUID(),
            senderName: "Mike R.",
            senderInitials: "MR",
            avatarColorIndex: 1,
            profilePhoto: nil,
            text: "Nice! What's your daily target?",
            timestamp: Date().addingTimeInterval(-3000),
            replyTo: "Just hit my protein goal for the first time this week!",
            reactions: []
        ),
        GroupMessage(
            id: UUID(),
            senderName: "Sarah M.",
            senderInitials: "SM",
            avatarColorIndex: 0,
            profilePhoto: nil,
            text: "150g — it's tough but Qyra makes tracking so easy",
            timestamp: Date().addingTimeInterval(-2400),
            replyTo: nil,
            reactions: [
                GroupReaction(emoji: "\u{1F44D}", count: 1, isSelected: false),
            ]
        ),
        GroupMessage(
            id: UUID(),
            senderName: "Alex K.",
            senderInitials: "AK",
            avatarColorIndex: 2,
            profilePhoto: nil,
            text: "I'm at 140g target. Greek yogurt has been a game changer for me",
            timestamp: Date().addingTimeInterval(-1800),
            replyTo: nil,
            reactions: []
        ),
        GroupMessage(
            id: UUID(),
            senderName: "Jordan L.",
            senderInitials: "JL",
            avatarColorIndex: 3,
            profilePhoto: nil,
            text: "Just finished a 5K! Logged it with the exercise tracker",
            timestamp: Date().addingTimeInterval(-600),
            replyTo: nil,
            reactions: [
                GroupReaction(emoji: "\u{1F389}", count: 4, isSelected: true),
            ]
        ),
    ]
}

// MARK: - Leaderboard Entry

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let rank: Int
    let name: String
    let initials: String
    let avatarColorIndex: Int
    let score: Int  // weekly calories tracked
    let isCurrentUser: Bool

    static let sampleEntries: [LeaderboardEntry] = [
        LeaderboardEntry(id: UUID(), rank: 1, name: "Sarah M.", initials: "SM", avatarColorIndex: 0, score: 14280, isCurrentUser: false),
        LeaderboardEntry(id: UUID(), rank: 2, name: "Mike R.", initials: "MR", avatarColorIndex: 1, score: 12450, isCurrentUser: false),
        LeaderboardEntry(id: UUID(), rank: 3, name: "Alex K.", initials: "AK", avatarColorIndex: 2, score: 11890, isCurrentUser: false),
        LeaderboardEntry(id: UUID(), rank: 4, name: "You", initials: "BT", avatarColorIndex: 4, score: 10200, isCurrentUser: true),
        LeaderboardEntry(id: UUID(), rank: 5, name: "Jordan L.", initials: "JL", avatarColorIndex: 3, score: 9800, isCurrentUser: false),
        LeaderboardEntry(id: UUID(), rank: 6, name: "Casey P.", initials: "CP", avatarColorIndex: 5, score: 8400, isCurrentUser: false),
    ]
}

// MARK: - Group Reaction

struct GroupReaction: Identifiable {
    let id = UUID()
    let emoji: String
    let count: Int
    let isSelected: Bool
}
