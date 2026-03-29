import Foundation
import os

/// Service for creating, joining, and querying 1v1 versus matches via Supabase REST API.
/// Complements the existing versus_challenges/versus_participants tables with a simpler
/// invite-code-based 1v1 match flow stored in the versus_matches table.
@MainActor
final class VersusMatchService: ObservableObject {

    static let shared = VersusMatchService()

    @Published var myMatches: [VersusMatchRow] = []
    @Published var isLoading = false
    @Published var error: String?

    private let baseURL = "https://oqjmxdxcwsajawesyspa.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam14ZHhjd3NhamF3ZXN5c3BhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NTAyMTQsImV4cCI6MjA4ODIyNjIxNH0.m5tLk5asnA9Jb-lZ64Tg9RiKNbSk3gH6QE8qbBPBRG4"
    private let logger = Logger(subsystem: "co.tamras.qyra", category: "VersusMatch")

    // MARK: - REST Model

    struct VersusMatchRow: Codable, Identifiable {
        let id: String
        let challenger_id: String
        let opponent_id: String?
        let metric: String
        let duration_days: Int
        let stakes: String?
        let status: String
        let invite_code: String?
        let challenger_score: Double?
        let opponent_score: Double?
        let starts_at: String?
        let ends_at: String?
        let created_at: String
        let updated_at: String

        var metricDisplay: String {
            switch metric {
            case "calories_burned": return "Calories Burned"
            case "protein_grams": return "Protein (g)"
            case "steps": return "Steps"
            case "calories_consumed": return "Calories Consumed"
            default: return metric.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }

        var isActive: Bool { status == "active" }
        var isPending: Bool { status == "pending" }
    }

    // MARK: - Create Match

    /// Creates a new 1v1 versus match. The current user becomes the challenger.
    /// - Parameters:
    ///   - metric: One of: calories_burned, protein_grams, steps, calories_consumed
    ///   - durationDays: One of: 1, 3, 7, 14, 30
    ///   - stakes: Optional stakes text (max 200 chars)
    ///   - userId: Current user's auth UUID string
    /// - Returns: The created match row (including invite_code for sharing)
    @discardableResult
    func createMatch(
        metric: String,
        durationDays: Int,
        stakes: String? = nil,
        userId: String
    ) async throws -> VersusMatchRow {
        let inviteCode = generateInviteCode()

        let urlString = "\(baseURL)/rest/v1/versus_matches"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        if let token = AuthService.shared.currentUserId {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body: [String: Any] = [
            "challenger_id": userId,
            "metric": metric,
            "duration_days": durationDays,
            "invite_code": inviteCode,
            "status": "pending"
        ]
        if let stakes, !stakes.isEmpty {
            body["stakes"] = String(stakes.prefix(200))
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("Create match failed: \(code) \(errorBody)")
            throw ServiceError.serverError(code, errorBody)
        }

        let rows = try JSONDecoder().decode([VersusMatchRow].self, from: data)
        guard let match = rows.first else { throw ServiceError.decodingFailed }

        logger.info("Match created: \(match.id) invite=\(inviteCode)")
        return match
    }

    // MARK: - Join Match

    /// Joins an existing match by invite code. Sets the opponent_id and activates the match.
    /// - Parameters:
    ///   - inviteCode: The 6-char invite code
    ///   - userId: Current user's auth UUID string
    func joinMatch(inviteCode: String, userId: String) async throws -> VersusMatchRow {
        let code = inviteCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // First, find the match by invite code
        let findURL = "\(baseURL)/rest/v1/versus_matches?invite_code=eq.\(code)&status=eq.pending&select=*"
        guard let url = URL(string: findURL) else { throw ServiceError.invalidURL }

        var findReq = URLRequest(url: url)
        findReq.httpMethod = "GET"
        findReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        findReq.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = AuthService.shared.currentUserId {
            findReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (findData, findResp) = try await URLSession.shared.data(for: findReq)
        guard let findHttp = findResp as? HTTPURLResponse, (200...299).contains(findHttp.statusCode) else {
            throw ServiceError.serverError((findResp as? HTTPURLResponse)?.statusCode ?? -1, "Lookup failed")
        }

        let matches = try JSONDecoder().decode([VersusMatchRow].self, from: findData)
        guard let match = matches.first else {
            throw ServiceError.notFound("No pending match with that code")
        }

        guard match.challenger_id != userId else {
            throw ServiceError.validationFailed("You cannot join your own match")
        }

        // Update the match: set opponent, activate, set start/end times
        let now = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: match.duration_days, to: now) ?? now
        let iso = ISO8601DateFormatter()

        let updateURL = "\(baseURL)/rest/v1/versus_matches?id=eq.\(match.id)"
        guard let patchURL = URL(string: updateURL) else { throw ServiceError.invalidURL }

        var patchReq = URLRequest(url: patchURL)
        patchReq.httpMethod = "PATCH"
        patchReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
        patchReq.setValue(anonKey, forHTTPHeaderField: "apikey")
        patchReq.setValue("return=representation", forHTTPHeaderField: "Prefer")
        if let token = AuthService.shared.currentUserId {
            patchReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let updateBody: [String: Any] = [
            "opponent_id": userId,
            "status": "active",
            "starts_at": iso.string(from: now),
            "ends_at": iso.string(from: endDate),
            "updated_at": iso.string(from: now)
        ]
        patchReq.httpBody = try JSONSerialization.data(withJSONObject: updateBody)

        let (patchData, patchResp) = try await URLSession.shared.data(for: patchReq)
        guard let patchHttp = patchResp as? HTTPURLResponse, (200...299).contains(patchHttp.statusCode) else {
            let code = (patchResp as? HTTPURLResponse)?.statusCode ?? -1
            throw ServiceError.serverError(code, "Join failed")
        }

        let updated = try JSONDecoder().decode([VersusMatchRow].self, from: patchData)
        guard let result = updated.first else { throw ServiceError.decodingFailed }

        logger.info("Joined match \(result.id)")
        return result
    }

    // MARK: - Fetch My Matches

    /// Fetches all matches where the current user is challenger or opponent.
    func fetchMyMatches(userId: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        let urlString = "\(baseURL)/rest/v1/versus_matches?or=(challenger_id.eq.\(userId),opponent_id.eq.\(userId))&order=created_at.desc&select=*"
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
            logger.error("Fetch matches failed: \(code)")
            throw ServiceError.serverError(code, "Fetch failed")
        }

        myMatches = try JSONDecoder().decode([VersusMatchRow].self, from: data)
        logger.info("Fetched \(self.myMatches.count) versus matches")
    }

    // MARK: - Update Score

    /// Updates the score for the current user on an active match.
    func updateScore(matchId: String, userId: String, score: Double) async throws {
        guard let match = myMatches.first(where: { $0.id == matchId }) else {
            throw ServiceError.notFound("Match not found locally")
        }

        let isChallenger = match.challenger_id == userId
        let scoreField = isChallenger ? "challenger_score" : "opponent_score"

        let urlString = "\(baseURL)/rest/v1/versus_matches?id=eq.\(matchId)"
        guard let url = URL(string: urlString) else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let token = AuthService.shared.currentUserId {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            scoreField: score,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw ServiceError.serverError((response as? HTTPURLResponse)?.statusCode ?? -1, "Score update failed")
        }

        logger.info("Score updated for match \(matchId)")
    }

    // MARK: - Helpers

    private func generateInviteCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // No ambiguous chars (0/O, 1/I)
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    // MARK: - Errors

    enum ServiceError: LocalizedError {
        case invalidURL
        case serverError(Int, String)
        case decodingFailed
        case notFound(String)
        case validationFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
            case .decodingFailed: return "Failed to decode response"
            case .notFound(let msg): return msg
            case .validationFailed(let msg): return msg
            }
        }
    }
}
