import Foundation

actor OpenFoodFactsService {
    static let shared = OpenFoodFactsService()

    private let baseURL = "https://world.openfoodfacts.org/api/v2"

    // MARK: - Barcode Lookup

    func lookupBarcode(_ barcode: String) async throws -> FoodAnalysisResult? {
        let url = "\(baseURL)/product/\(barcode).json"

        guard let urlObj = URL(string: url) else { throw APIError.invalidURL }
        var request = URLRequest(url: urlObj)
        request.setValue("MACRA-iOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return nil
        }

        return try parseProduct(from: data, barcode: barcode)
    }

    // MARK: - Parsing

    private func parseProduct(from data: Data, barcode: String) throws -> FoodAnalysisResult? {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int, status == 1,
              let product = json["product"] as? [String: Any]
        else {
            return nil
        }

        let name = product["product_name"] as? String ?? "Unknown Product"
        let brand = product["brands"] as? String
        let imageURL = product["image_front_url"] as? String

        guard let nutriments = product["nutriments"] as? [String: Any] else {
            return FoodAnalysisResult(
                name: name,
                calories: 0, protein: 0, carbs: 0, fat: 0,
                confidence: 30,
                brand: brand,
                barcode: barcode,
                imageURL: imageURL
            )
        }

        let calories = nutrimentValue(nutriments, key: "energy-kcal_100g")
        let protein = nutrimentValue(nutriments, key: "proteins_100g")
        let carbs = nutrimentValue(nutriments, key: "carbohydrates_100g")
        let fat = nutrimentValue(nutriments, key: "fat_100g")
        let fiber = nutrimentValue(nutriments, key: "fiber_100g")
        let sugar = nutrimentValue(nutriments, key: "sugars_100g")
        let sodium = nutrimentValue(nutriments, key: "sodium_100g")

        // Get serving size
        let servingSize = product["serving_size"] as? String
        let servingQuantity = product["serving_quantity"] as? Double ?? 100

        // Scale from per-100g to per-serving
        let scale = servingQuantity / 100.0

        return FoodAnalysisResult(
            name: name,
            calories: calories * scale,
            protein: protein * scale,
            carbs: carbs * scale,
            fat: fat * scale,
            fiber: fiber > 0 ? fiber * scale : nil,
            sugar: sugar > 0 ? sugar * scale : nil,
            sodium: sodium > 0 ? sodium * scale : nil,
            servingSize: servingSize ?? "\(Int(servingQuantity))g",
            confidence: 90,
            brand: brand,
            barcode: barcode,
            imageURL: imageURL
        )
    }

    private func nutrimentValue(_ nutriments: [String: Any], key: String) -> Double {
        if let value = nutriments[key] as? Double { return value }
        if let value = nutriments[key] as? Int { return Double(value) }
        if let str = nutriments[key] as? String, let value = Double(str) { return value }
        return 0
    }
}
