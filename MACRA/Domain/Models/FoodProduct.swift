import Foundation
import SwiftData

// INTEGRATED FROM: Open Food Facts, USDA FoodData Central
// Local cache for food products from external nutrition databases.
// Enables offline barcode lookup and food search.

@Model
final class FoodProduct {
    @Attribute(.unique) var barcode: String
    var name: String
    var brands: String?
    var categories: String?
    var imageURL: String?

    // Nutrition per 100g
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fiberPer100g: Double?
    var sugarPer100g: Double?
    var sodiumPer100g: Double?

    // Serving
    var servingSize: String?
    var servingSizeGrams: Double?

    // Metadata
    var nutriScore: String?
    var novaGroup: Int?
    var allergens: String?
    var ingredients: String?
    var source: String
    var lastUpdated: Date

    // Search optimization
    var searchName: String

    init(
        barcode: String,
        name: String,
        brands: String? = nil,
        categories: String? = nil,
        imageURL: String? = nil,
        caloriesPer100g: Double = 0,
        proteinPer100g: Double = 0,
        carbsPer100g: Double = 0,
        fatPer100g: Double = 0,
        fiberPer100g: Double? = nil,
        sugarPer100g: Double? = nil,
        sodiumPer100g: Double? = nil,
        servingSize: String? = nil,
        servingSizeGrams: Double? = nil,
        nutriScore: String? = nil,
        novaGroup: Int? = nil,
        allergens: String? = nil,
        ingredients: String? = nil,
        source: String = "openfoodfacts"
    ) {
        self.barcode = barcode
        self.name = name
        self.brands = brands
        self.categories = categories
        self.imageURL = imageURL
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g
        self.fatPer100g = fatPer100g
        self.fiberPer100g = fiberPer100g
        self.sugarPer100g = sugarPer100g
        self.sodiumPer100g = sodiumPer100g
        self.servingSize = servingSize
        self.servingSizeGrams = servingSizeGrams
        self.nutriScore = nutriScore
        self.novaGroup = novaGroup
        self.allergens = allergens
        self.ingredients = ingredients
        self.source = source
        self.lastUpdated = .now
        self.searchName = name.lowercased()
    }

    // MARK: - Conversion

    /// Convert to FoodAnalysisResult scaled to serving size
    func toFoodAnalysisResult() -> FoodAnalysisResult {
        let scale = (servingSizeGrams ?? 100) / 100.0
        return FoodAnalysisResult(
            name: name,
            calories: caloriesPer100g * scale,
            protein: proteinPer100g * scale,
            carbs: carbsPer100g * scale,
            fat: fatPer100g * scale,
            fiber: fiberPer100g.map { $0 * scale },
            sugar: sugarPer100g.map { $0 * scale },
            sodium: sodiumPer100g.map { $0 * scale },
            servingSize: servingSize ?? "\(Int(servingSizeGrams ?? 100))g",
            confidence: 90,
            brand: brands,
            barcode: barcode,
            imageURL: imageURL
        )
    }
}
