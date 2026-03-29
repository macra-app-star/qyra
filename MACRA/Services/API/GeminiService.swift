import Foundation

actor GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    // MARK: - Analyze Food Photo

    func analyzeFoodPhoto(imageData: Data) async throws -> [FoodAnalysisResult] {
        let apiKey = Secrets.geminiAPIKey
        guard !apiKey.isEmpty else {
            throw APIError.unauthorized
        }

        let base64Image = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": foodPhotoPrompt
                        ],
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let url = "\(baseURL)?key=\(apiKey)"

        let responseData = try await APIClient.shared.postRaw(url: url, body: body)
        return try parseGeminiResponse(responseData)
    }

    // MARK: - Parse Natural Language

    func parseNaturalLanguage(text: String) async throws -> [FoodAnalysisResult] {
        let apiKey = Secrets.geminiAPIKey
        guard !apiKey.isEmpty else {
            throw APIError.unauthorized
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": naturalLanguagePrompt(for: text)
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let url = "\(baseURL)?key=\(apiKey)"

        let responseData = try await APIClient.shared.postRaw(url: url, body: body)
        return try parseGeminiResponse(responseData)
    }

    // MARK: - Chat (AI Coach)

    func chat(userMessage: String, systemContext: String) async throws -> String {
        let apiKey = Secrets.geminiAPIKey
        guard !apiKey.isEmpty else {
            throw APIError.unauthorized
        }

        let chatURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "\(systemContext)\n\nUser: \(userMessage)"]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 1024
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let responseData = try await APIClient.shared.postRaw(url: chatURL, body: body)

        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any] else {
            let raw = String(data: responseData, encoding: .utf8) ?? "<binary>"
            #if DEBUG
            print("[GeminiService] chat: Failed to parse JSON. Raw: \(raw.prefix(500))")
            #endif
            throw APIError.decodingFailed(
                NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
            )
        }

        // Check for API-level error in the JSON body
        if let error = json["error"] as? [String: Any] {
            let message = error["message"] as? String ?? "Unknown API error"
            let code = error["code"] as? Int ?? -1
            #if DEBUG
            print("[GeminiService] chat: API error \(code): \(message)")
            #endif
            if code == 403 || code == 401 {
                throw APIError.unauthorized
            }
            throw APIError.decodingFailed(
                NSError(domain: "GeminiService", code: code, userInfo: [NSLocalizedDescriptionKey: message])
            )
        }

        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else {
            #if DEBUG
            print("[GeminiService] chat: Unexpected response keys: \(json.keys.sorted())")
            #endif
            throw APIError.decodingFailed(
                NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid chat response structure"])
            )
        }

        return text
    }

    // MARK: - Response Parsing

    private func parseGeminiResponse(_ data: Data) throws -> [FoodAnalysisResult] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let textPart = parts.first?["text"] as? String
        else {
            throw APIError.decodingFailed(
                NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Gemini response structure"])
            )
        }

        // Robust JSON cleaning — handles markdown fences, BOM, extra text
        let cleanedText = cleanJSONResponse(textPart)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw APIError.decodingFailed(
                NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid text encoding"])
            )
        }

        #if DEBUG
        if cleanedText != textPart {
            print("[GeminiService] Cleaned response: \(textPart.prefix(80))... → \(cleanedText.prefix(80))...")
        }
        #endif

        let items = try JSONDecoder().decode([GeminiFoodItem].self, from: jsonData)

        return items.map { item in
            FoodAnalysisResult(
                name: item.name,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                fiber: item.fiber,
                servingSize: item.servingSize,
                confidence: item.confidence ?? 75,
                explanation: item.explanation,
                assumptions: item.assumptions
            )
        }
    }

    // MARK: - JSON Cleaning

    private func cleanJSONResponse(_ raw: String) -> String {
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown code fences: ```json ... ``` or ``` ... ```
        if cleaned.hasPrefix("```") {
            if let firstNewline = cleaned.firstIndex(of: "\n") {
                cleaned = String(cleaned[cleaned.index(after: firstNewline)...])
            }
            if cleaned.hasSuffix("```") {
                cleaned = String(cleaned.dropLast(3))
            }
            cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Strip BOM if present
        if cleaned.hasPrefix("\u{FEFF}") {
            cleaned = String(cleaned.dropFirst())
        }

        // Find first JSON object or array
        if !cleaned.hasPrefix("{") && !cleaned.hasPrefix("[") {
            if let jsonStart = cleaned.firstIndex(of: "{") {
                cleaned = String(cleaned[jsonStart...])
            } else if let jsonStart = cleaned.firstIndex(of: "[") {
                cleaned = String(cleaned[jsonStart...])
            }
        }

        // Trim anything after the last closing brace/bracket
        if cleaned.hasPrefix("{"), let lastBrace = cleaned.lastIndex(of: "}") {
            cleaned = String(cleaned[...lastBrace])
        } else if cleaned.hasPrefix("["), let lastBracket = cleaned.lastIndex(of: "]") {
            cleaned = String(cleaned[...lastBracket])
        }

        return cleaned
    }

    // MARK: - Prompts

    private var foodPhotoPrompt: String {
        """
        Analyze this food photo. Identify every food item visible and estimate the nutritional content for each.

        Return a JSON array where each object has these exact fields:
        - "name": string (food item name, be specific e.g. "Grilled Chicken Breast" not just "chicken")
        - "calories": number (estimated calories)
        - "protein": number (grams of protein)
        - "carbs": number (grams of carbohydrates)
        - "fat": number (grams of fat)
        - "fiber": number or null (grams of fiber if estimable)
        - "serving_size": string (estimated portion like "1 cup", "6 oz", "1 medium")
        - "confidence": number (0-100, how confident you are)
        - "explanation": string (1-2 sentences explaining how you identified this item and estimated the portion)
        - "assumptions": array of strings (key assumptions like milk type, cooking method, portion basis)

        Be precise with portion estimation. If you can see the plate or container size, use it as reference.
        If multiple food items are visible, list each one separately.
        Only return the JSON array, no other text.
        """
    }

    private func naturalLanguagePrompt(for text: String) -> String {
        """
        Parse this food description into individual food items with estimated nutritional content:

        "\(text)"

        Return a JSON array where each object has these exact fields:
        - "name": string (food item name, be specific)
        - "calories": number (estimated calories)
        - "protein": number (grams of protein)
        - "carbs": number (grams of carbohydrates)
        - "fat": number (grams of fat)
        - "fiber": number or null (grams of fiber if estimable)
        - "serving_size": string (estimated portion like "1 cup", "6 oz", "1 medium")
        - "confidence": number (0-100, how confident you are in the estimates)

        Use standard serving sizes if not specified. Be reasonable with estimates based on typical portions.
        Only return the JSON array, no other text.
        """
    }
}

// MARK: - Gemini Response DTOs

private struct GeminiFoodItem: Decodable {
    let name: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let servingSize: String?
    let confidence: Int?
    let explanation: String?
    let assumptions: [String]?

    enum CodingKeys: String, CodingKey {
        case name, calories, protein, carbs, fat, fiber, explanation, assumptions
        case servingSize = "serving_size"
        case confidence
    }
}
