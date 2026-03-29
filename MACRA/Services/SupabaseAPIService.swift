import Foundation
import os

actor SupabaseAPIService {

    static let shared = SupabaseAPIService()

    private let baseURL = "https://oqjmxdxcwsajawesyspa.supabase.co"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xam14ZHhjd3NhamF3ZXN5c3BhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI2NTAyMTQsImV4cCI6MjA4ODIyNjIxNH0.m5tLk5asnA9Jb-lZ64Tg9RiKNbSk3gH6QE8qbBPBRG4"
    private let logger = Logger(subsystem: "co.tamras.qyra", category: "API")

    // MARK: - Auth Token

    @MainActor
    private func authToken() -> String? {
        // Prefer real Supabase JWT; fall back to Apple user ID for edge-function calls
        AuthService.shared.supabaseAccessToken ?? AuthService.shared.currentUserId
    }

    // MARK: - Base Request

    private func makeRequest(
        path: String,
        method: String = "POST",
        body: [String: Any]? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> Data {
        var urlString = "\(baseURL)/functions/v1/\(path)"

        if let queryParams, !queryParams.isEmpty {
            let query = queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            urlString += "?\(query)"
        }

        guard let url = URL(string: urlString) else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")

        let token = await authToken()
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown"
            logger.error("API \(httpResponse.statusCode): \(errorBody)")
            switch httpResponse.statusCode {
            case 401: throw APIError.unauthorized
            case 404: throw APIError.notFound
            case 409: throw APIError.conflict
            default:  throw APIError.serverError(httpResponse.statusCode, errorBody)
            }
        }

        return data
    }

    // MARK: - Groups

    struct GroupResponse: Codable {
        let id: String
        let name: String
        let invite_code: String
        let created_by: String
        let is_private: Bool?
        let max_members: Int?
        let created_at: String?
    }

    func createGroup(name: String, isPrivate: Bool = false) async throws -> GroupResponse {
        let data = try await makeRequest(path: "group-create", body: ["name": name, "is_private": isPrivate])
        let wrapper = try JSONDecoder().decode([String: GroupResponse].self, from: data)
        guard let group = wrapper["group"] else { throw APIError.decodingFailed }
        return group
    }

    func joinGroup(inviteCode: String) async throws -> GroupResponse {
        let data = try await makeRequest(path: "group-join", body: ["invite_code": inviteCode.uppercased().trimmingCharacters(in: .whitespaces)])
        struct JoinResponse: Codable { let success: Bool; let group: GroupResponse }
        return try JSONDecoder().decode(JoinResponse.self, from: data).group
    }

    func fetchMyGroups() async throws -> [GroupResponse] {
        let data = try await makeRequest(path: "group-details", method: "GET")
        struct ListResponse: Codable { let groups: [GroupResponse] }
        return try JSONDecoder().decode(ListResponse.self, from: data).groups
    }

    // MARK: - Profile

    func upsertProfile(userId: String, username: String, displayName: String) async throws {
        let url = URL(string: "\(baseURL)/rest/v1/profiles")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation,resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let token = await authToken()
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let body: [String: Any] = ["id": userId, "username": username, "display_name": displayName, "updated_at": ISO8601DateFormatter().string(from: Date())]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500, "Profile upsert failed")
        }
        await Self.stampSyncDate()
    }

    // MARK: - Daily Stats

    func syncDailyStats(userId: String, date: Date, calories: Int, protein: Double, carbs: Double, fat: Double, mealsLogged: Int, workoutsLogged: Int, waterOz: Double, streakDays: Int) async throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let url = URL(string: "\(baseURL)/rest/v1/daily_stats")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        let token = await authToken()
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let body: [String: Any] = [
            "user_id": userId, "stat_date": dateFormatter.string(from: date),
            "calories_consumed": calories, "protein_g": protein, "carbs_g": carbs, "fat_g": fat,
            "meals_logged": mealsLogged, "workouts_logged": workoutsLogged,
            "water_oz": waterOz, "streak_days": streakDays,
            "updated_at": ISO8601DateFormatter().string(from: Date())
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500, "Stats sync failed")
        }
        await Self.stampSyncDate()
    }

    // MARK: - AI Coach

    func chatWithCoach(messages: [[String: String]], context: String) async throws -> String {
        let body: [String: Any] = [
            "messages": messages,
            "context": context
        ]
        let data = try await makeRequest(path: "qyra-ai-chat", body: body)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let reply = json["reply"] as? String else {
            throw APIError.decodingFailed
        }
        return reply
    }

    // MARK: - Delete Account

    func deleteAccount() async throws {
        _ = try await makeRequest(path: "delete-account", method: "POST")
    }

    // MARK: - Sync Timestamp

    static let lastSyncDateKey = "qyra.lastSyncDate"

    @MainActor
    static func stampSyncDate() {
        UserDefaults.standard.set(Date(), forKey: lastSyncDateKey)
    }

    static var lastSyncDate: Date? {
        UserDefaults.standard.object(forKey: lastSyncDateKey) as? Date
    }

    // MARK: - Errors

    enum APIError: LocalizedError {
        case invalidURL, invalidResponse, unauthorized, notFound, conflict, decodingFailed
        case serverError(Int, String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response"
            case .unauthorized: return "Please sign in again"
            case .notFound: return "Not found"
            case .conflict: return "Already exists"
            case .decodingFailed: return "Data error"
            case .serverError(let code, let msg): return "Server error \(code): \(msg)"
            }
        }
    }
}
