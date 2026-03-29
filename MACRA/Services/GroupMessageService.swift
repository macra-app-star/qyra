import Foundation
import os

/// Service for sending and fetching group chat messages via Supabase REST API.
/// Uses the same raw URLSession pattern as SupabaseAPIService.
@MainActor
final class GroupMessageService: ObservableObject {

    static let shared = GroupMessageService()

    @Published var messages: [GroupMessage] = []
    @Published var isLoading = false
    @Published var error: String?

    private let baseURL = "https://oqjmxdxcwsajawesyspa.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam14ZHhjd3NhamF3ZXN5c3BhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NTAyMTQsImV4cCI6MjA4ODIyNjIxNH0.m5tLk5asnA9Jb-lZ64Tg9RiKNbSk3gH6QE8qbBPBRG4"
    private let logger = Logger(subsystem: "co.tamras.qyra", category: "GroupMessages")

    // MARK: - REST Models

    struct MessageRow: Codable {
        let id: String
        let group_id: String
        let user_id: String
        let content: String
        let created_at: String
    }

    // MARK: - Fetch Messages

    /// Fetches the most recent messages for a group, ordered newest-first.
    /// - Parameters:
    ///   - groupId: The UUID string of the group.
    ///   - limit: Max messages to return (default 50).
    func fetchMessages(groupId: String, limit: Int = 50) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let urlString = "\(baseURL)/rest/v1/group_messages?group_id=eq.\(groupId)&order=created_at.desc&limit=\(limit)&select=*"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        if let token = AuthService.shared.currentUserId {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("Fetch messages failed: \(code)")
            throw ServiceError.serverError(code)
        }

        let rows = try JSONDecoder().decode([MessageRow].self, from: data)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Map REST rows to the UI GroupMessage model (reverse to chronological order)
        messages = rows.reversed().map { row in
            let initials = String(row.user_id.prefix(2)).uppercased()
            let date = formatter.date(from: row.created_at) ?? Date()
            return GroupMessage(
                id: UUID(uuidString: row.id) ?? UUID(),
                senderName: row.user_id, // Will be enriched with profile data later
                senderInitials: initials,
                avatarColorIndex: abs(row.user_id.hashValue) % 6,
                profilePhoto: nil,
                text: row.content,
                timestamp: date,
                replyTo: nil,
                reactions: []
            )
        }

        logger.info("Fetched \(rows.count) messages for group \(groupId)")
    }

    // MARK: - Send Message

    /// Inserts a new message into the group_messages table.
    /// - Parameters:
    ///   - content: Message text (1-2000 chars).
    ///   - groupId: The UUID string of the group.
    ///   - userId: The current user's auth UUID string.
    func sendMessage(content: String, groupId: String, userId: String) async throws {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 2000 else {
            throw ServiceError.validationFailed("Message must be 1-2000 characters")
        }

        let urlString = "\(baseURL)/rest/v1/group_messages"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        if let token = AuthService.shared.currentUserId {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "group_id": groupId,
            "user_id": userId,
            "content": trimmed
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("Send message failed: \(code) \(errorBody)")
            throw ServiceError.serverError(code)
        }

        logger.info("Message sent to group \(groupId)")

        // Append the new message locally for instant UI update
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let rows = try? JSONDecoder().decode([MessageRow].self, from: data), let row = rows.first {
            let date = formatter.date(from: row.created_at) ?? Date()
            let newMessage = GroupMessage(
                id: UUID(uuidString: row.id) ?? UUID(),
                senderName: "You",
                senderInitials: String(AuthService.shared.currentUserName?.prefix(2) ?? "ME").uppercased(),
                avatarColorIndex: abs(userId.hashValue) % 6,
                profilePhoto: nil,
                text: row.content,
                timestamp: date,
                replyTo: nil,
                reactions: []
            )
            messages.append(newMessage)
        }
    }

    // MARK: - Errors

    enum ServiceError: LocalizedError {
        case invalidURL
        case serverError(Int)
        case validationFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .serverError(let code): return "Server error (\(code))"
            case .validationFailed(let msg): return msg
            }
        }
    }
}
