import Foundation

actor GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

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

        // Parse the JSON array from the text response
        guard let jsonData = textPart.data(using: .utf8) else {
            throw APIError.decodingFailed(
                NSError(domain: "GeminiService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid text encoding"])
            )
        }

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
                confidence: item.confidence ?? 75
            )
        }
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
        - "confidence": number (0-100, how confident you are in the identification and estimates)

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

    enum CodingKeys: String, CodingKey {
        case name, calories, protein, carbs, fat, fiber
        case servingSize = "serving_size"
        case confidence
    }
}
