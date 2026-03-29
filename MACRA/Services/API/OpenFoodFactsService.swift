import Foundation

actor OpenFoodFactsService {
    static let shared = OpenFoodFactsService()

    private let baseURL = "https://world.openfoodfacts.org/api/v2"

    // MARK: - Barcode Lookup (Basic — for NutritionService cache)

    func lookupBarcode(_ barcode: String) async throws -> FoodAnalysisResult? {
        guard let analysis = try await lookupProduct(barcode) else { return nil }
        return analysis.toFoodAnalysisResult()
    }

    // MARK: - Rich Product Lookup (for ProductAnalysisView)

    func lookupProduct(_ barcode: String) async throws -> ProductAnalysis? {
        let url = "\(baseURL)/product/\(barcode).json"

        guard let urlObj = URL(string: url) else { throw APIError.invalidURL }
        var request = URLRequest(url: urlObj)
        request.setValue("Qyra-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        return try parseProductAnalysis(from: data, barcode: barcode)
    }

    // MARK: - Parsing

    private func parseProductAnalysis(from data: Data, barcode: String) throws -> ProductAnalysis? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let product = json["product"] as? [String: Any]
        else {
            return nil
        }

        let name = product["product_name"] as? String ?? "Unknown Product"
        let brand = product["brands"] as? String
        let imageURL = product["image_front_url"] as? String
            ?? product["image_url"] as? String

        // Nutriments
        let nutriments = product["nutriments"] as? [String: Any] ?? [:]
        let caloriesPer100g = nutrimentValue(nutriments, key: "energy-kcal_100g")
        let proteinPer100g = nutrimentValue(nutriments, key: "proteins_100g")
        let carbsPer100g = nutrimentValue(nutriments, key: "carbohydrates_100g")
        let fatPer100g = nutrimentValue(nutriments, key: "fat_100g")
        let fiberPer100g = nutrimentValue(nutriments, key: "fiber_100g")
        let sugarPer100g = nutrimentValue(nutriments, key: "sugars_100g")
        let sodiumPer100g = nutrimentValue(nutriments, key: "sodium_100g")
        let saturatedFatPer100g = nutrimentValue(nutriments, key: "saturated-fat_100g")

        // Serving size
        let servingSize = product["serving_size"] as? String
        let servingQuantity = product["serving_quantity"] as? Double ?? 100
        let scale = servingQuantity / 100.0

        // Nutri-Score
        let nutriScore = product["nutriscore_grade"] as? String
            ?? product["nutrition_grades"] as? String

        // Ingredients
        let ingredientsText = product["ingredients_text"] as? String
            ?? product["ingredients_text_en"] as? String

        // Additives
        let additiveTags = product["additives_tags"] as? [String] ?? []
        let additives = additiveTags.map { tag in
            tag.replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }

        // Allergens
        let allergenTags = product["allergens_tags"] as? [String] ?? []
        let allergens = allergenTags.map { tag in
            tag.replacingOccurrences(of: "en:", with: "").capitalized
        }

        // Nutrient levels
        var nutrientLevels: NutrientLevels?
        if let levels = product["nutrient_levels"] as? [String: String] {
            nutrientLevels = NutrientLevels(
                fat: NutrientLevel(rawValue: levels["fat"] ?? ""),
                saturatedFat: NutrientLevel(rawValue: levels["saturated-fat"] ?? ""),
                sugars: NutrientLevel(rawValue: levels["sugars"] ?? ""),
                salt: NutrientLevel(rawValue: levels["salt"] ?? "")
            )
        }

        // Labels
        let labelTags = product["labels_tags"] as? [String] ?? []
        let labels = labelTags.map { tag in
            tag.replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
        }

        return ProductAnalysis(
            name: name,
            brand: brand,
            barcode: barcode,
            imageURL: imageURL,
            calories: caloriesPer100g * scale,
            protein: proteinPer100g * scale,
            carbs: carbsPer100g * scale,
            fat: fatPer100g * scale,
            fiber: fiberPer100g > 0 ? fiberPer100g * scale : nil,
            sugar: sugarPer100g > 0 ? sugarPer100g * scale : nil,
            sodium: sodiumPer100g > 0 ? sodiumPer100g * scale : nil,
            saturatedFat: saturatedFatPer100g > 0 ? saturatedFatPer100g * scale : nil,
            servingSize: servingSize ?? "\(Int(servingQuantity))g",
            servingSizeGrams: servingQuantity,
            nutriScore: nutriScore,
            ingredients: ingredientsText,
            additives: additives,
            allergens: allergens,
            nutrientLevels: nutrientLevels,
            labels: labels
        )
    }

    private func nutrimentValue(_ nutriments: [String: Any], key: String) -> Double {
        if let value = nutriments[key] as? Double { return value }
        if let value = nutriments[key] as? Int { return Double(value) }
        if let str = nutriments[key] as? String, let value = Double(str) { return value }
        return 0
    }
}
