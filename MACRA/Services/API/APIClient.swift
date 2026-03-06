import Foundation

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(Error)
    case networkError(Error)
    case noData
    case rateLimited
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse(let code): return "Server error (HTTP \(code))"
        case .decodingFailed: return "Failed to parse response"
        case .networkError(let error): return error.localizedDescription
        case .noData: return "No data received"
        case .rateLimited: return "Rate limit exceeded. Try again shortly."
        case .unauthorized: return "Invalid API key"
        }
    }
}

// MARK: - API Client

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }

    // MARK: - GET

    func get<T: Decodable>(
        url: String,
        headers: [String: String] = [:],
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        guard var components = URLComponents(string: url) else {
            throw APIError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + queryItems
        }
        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return try await execute(request)
    }

    // MARK: - POST (JSON)

    func post<T: Decodable>(
        url: String,
        body: Data,
        headers: [String: String] = [:]
    ) async throws -> T {
        guard let finalURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        return try await execute(request)
    }

    // MARK: - POST (Raw Data Response)

    func postRaw(
        url: String,
        body: Data,
        headers: [String: String] = [:]
    ) async throws -> Data {
        guard let finalURL = URL(string: url) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        switch httpResponse.statusCode {
        case 200...299: return data
        case 401: throw APIError.unauthorized
        case 429: throw APIError.rateLimited
        default: throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Execute

    private func execute<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }

        switch httpResponse.statusCode {
        case 200...299: break
        case 401: throw APIError.unauthorized
        case 429: throw APIError.rateLimited
        default: throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}

// MARK: - Secrets

enum Secrets {
    private static var cache: [String: Any]?

    static func value(for key: String) -> String? {
        if cache == nil {
            guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
            else {
                // Fallback to environment variable (CI/CD)
                return ProcessInfo.processInfo.environment[key]
            }
            cache = plist
        }
        return cache?[key] as? String ?? ProcessInfo.processInfo.environment[key]
    }

    static var geminiAPIKey: String {
        value(for: "GEMINI_API_KEY") ?? ""
    }

    static var usdaAPIKey: String {
        value(for: "USDA_API_KEY") ?? ""
    }
}
