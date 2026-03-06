import Foundation

// MARK: - USDA Search Result

struct USDAFoodResult: Sendable, Identifiable, Equatable {
    let id: Int
    let name: String
    let brand: String?
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingSize: String?
    let servingWeight: Double?
    let dataType: String

    func toFoodAnalysisResult() -> FoodAnalysisResult {
        FoodAnalysisResult(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: servingSize ?? "100g",
            confidence: 95,
            brand: brand
        )
    }
}

// MARK: - USDA Service

actor USDAService {
    static let shared = USDAService()

    private let baseURL = "https://api.nal.usda.gov/fdc/v1"

    // MARK: - Search

    func search(query: String, pageSize: Int = 25) async throws -> [USDAFoodResult] {
        let apiKey = Secrets.usdaAPIKey
        guard !apiKey.isEmpty else {
            throw APIError.unauthorized
        }

        let requestBody: [String: Any] = [
            "query": query,
            "pageSize": pageSize,
            "dataType": ["Foundation", "SR Legacy", "Branded"],
            "sortBy": "dataType.keyword",
            "sortOrder": "asc"
        ]

        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let url = "\(baseURL)/foods/search?api_key=\(apiKey)"

        let responseData = try await APIClient.shared.postRaw(url: url, body: body)

        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let foods = json["foods"] as? [[String: Any]]
        else {
            return []
        }

        return foods.compactMap { parseFoodItem($0) }
    }

    // MARK: - Parsing

    private func parseFoodItem(_ food: [String: Any]) -> USDAFoodResult? {
        guard let fdcId = food["fdcId"] as? Int,
              let description = food["description"] as? String
        else { return nil }

        let nutrients = food["foodNutrients"] as? [[String: Any]] ?? []
        let brand = food["brandName"] as? String ?? food["brandOwner"] as? String
        let dataType = food["dataType"] as? String ?? ""

        var calories = 0.0
        var protein = 0.0
        var carbs = 0.0
        var fat = 0.0
        var fiber: Double?
        var sugar: Double?
        var sodium: Double?

        for nutrient in nutrients {
            guard let nutrientId = nutrient["nutrientId"] as? Int,
                  let value = nutrient["value"] as? Double
            else { continue }

            switch nutrientId {
            case 1008: calories = value        // Energy (kcal)
            case 1003: protein = value         // Protein
            case 1005: carbs = value           // Carbohydrate
            case 1004: fat = value             // Total lipid (fat)
            case 1079: fiber = value           // Fiber
            case 2000: sugar = value           // Total Sugars
            case 1093: sodium = value / 1000   // Sodium (mg → g)
            default: break
            }
        }

        // Serving size info
        let servingSize = food["servingSize"] as? Double
        let servingSizeUnit = food["servingSizeUnit"] as? String ?? "g"
        let householdServing = food["householdServingFullText"] as? String

        let servingLabel: String?
        if let household = householdServing {
            servingLabel = household
        } else if let size = servingSize {
            servingLabel = "\(Int(size))\(servingSizeUnit)"
        } else {
            servingLabel = "100g"
        }

        return USDAFoodResult(
            id: fdcId,
            name: description.capitalized,
            brand: brand,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: servingLabel,
            servingWeight: servingSize,
            dataType: dataType
        )
    }
}
