import SwiftUI
import SwiftData
import UIKit

@Observable @MainActor
final class GroupsViewModel {
    // MARK: - Published State
    var groups: [GroupModel] = []
    var selectedGroup: GroupModel? = nil
    var messages: [GroupMessage] = []
    var leaderboard: [LeaderboardEntry] = []

    // UI State
    var joinCode: String = ""
    var showJoinAlert: Bool = false
    var showCreateGroup: Bool = false
    var newGroupName: String = ""
    var newGroupIsPrivate: Bool = true

    // Feedback
    var lastCreatedInviteCode: String? = nil
    var showCreatedAlert: Bool = false
    var joinError: String? = nil
    var showJoinError: Bool = false
    var showJoinSuccess: Bool = false
    var joinedGroupName: String = ""

    // User profile for chat
    var userProfilePhoto: UIImage? = nil
    private var userDisplayName: String = ""
    private var userInitials: String = "ME"

    // Discovery groups -- placeholder until Supabase-backed
    let discoveryGroups: [GroupInfo] = []

    private var modelContext: ModelContext?

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchGroups()
    }

    // MARK: - CRUD

    func fetchGroups() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<GroupModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            groups = try modelContext.fetch(descriptor)
        } catch {
            groups = []
        }
    }

    func createGroup() {
        guard let modelContext else { return }
        let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 50 else { return }

        let group = GroupModel(name: trimmed, isPrivate: newGroupIsPrivate)
        modelContext.insert(group)

        do {
            try modelContext.save()
            lastCreatedInviteCode = group.inviteCode
            showCreatedAlert = true
            newGroupName = ""
            newGroupIsPrivate = true
            fetchGroups()
        } catch {
            // Silently fail for now
        }
    }

    func joinGroup() {
        guard let modelContext else { return }
        let code = joinCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !code.isEmpty else { return }

        let descriptor = FetchDescriptor<GroupModel>(
            predicate: #Predicate<GroupModel> { $0.inviteCode == code }
        )

        do {
            let matches = try modelContext.fetch(descriptor)
            if let group = matches.first {
                // Check if already in our list
                if groups.contains(where: { $0.id == group.id }) {
                    joinError = "You are already a member of \"\(group.name)\"."
                    showJoinError = true
                } else {
                    group.memberCount += 1
                    try modelContext.save()
                    joinedGroupName = group.name
                    showJoinSuccess = true
                    fetchGroups()
                }
            } else {
                joinError = "No group found with code \"\(code)\". Check the code and try again."
                showJoinError = true
            }
        } catch {
            joinError = "Something went wrong. Please try again."
            showJoinError = true
        }

        joinCode = ""
    }

    func loadUserProfile(container: ModelContainer) async {
        let repo = ProfileRepository(modelContainer: container)
        if let photoData = try? await repo.fetchProfilePhoto(),
           let image = UIImage(data: photoData) {
            userProfilePhoto = image
        }
        if let snapshot = try? await repo.fetchProfileSnapshot() {
            let name = snapshot.displayName ?? "You"
            userDisplayName = name
            let words = name.split(separator: " ").map(String.init)
            if words.count >= 2 {
                userInitials = (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased()
            } else if let first = words.first, !first.isEmpty {
                userInitials = String(first.prefix(2)).uppercased()
            }
        }
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let message = GroupMessage(
            id: UUID(),
            senderName: "You",
            senderInitials: userInitials,
            avatarColorIndex: 4,
            profilePhoto: userProfilePhoto,
            text: trimmed,
            timestamp: Date(),
            replyTo: nil,
            reactions: []
        )
        messages.append(message)
    }

    func deleteGroup(_ group: GroupModel) {
        guard let modelContext else { return }
        modelContext.delete(group)
        do {
            try modelContext.save()
            fetchGroups()
        } catch {
            // Silently fail
        }
    }
}
