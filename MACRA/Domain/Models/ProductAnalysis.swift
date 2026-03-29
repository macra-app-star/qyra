import SwiftUI

/// Rich product analysis data from OpenFoodFacts barcode lookup.
/// Contains nutrition, ingredients, additives, allergens, and health scoring.
struct ProductAnalysis: Sendable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let brand: String?
    let barcode: String
    let imageURL: String?

    // Nutrition per serving
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let saturatedFat: Double?
    let servingSize: String?
    let servingSizeGrams: Double?

    // Rich analysis
    let nutriScore: String?
    let ingredients: String?
    let additives: [String]
    let allergens: [String]
    let nutrientLevels: NutrientLevels?
    let labels: [String]

    // MARK: - Health Score (0-100, higher = better)

    var healthScore: Int {
        var score = 50

        // Nutri-Score mapping
        switch nutriScore?.lowercased() {
        case "a": score = 85
        case "b": score = 70
        case "c": score = 50
        case "d": score = 30
        case "e": score = 15
        default: break
        }

        // Adjust for additives
        if additives.count > 5 { score -= 15 }
        else if additives.count > 2 { score -= 8 }

        // Adjust for high sugar
        if let sugar, sugar > 15 { score -= 10 }

        // Adjust for high sodium
        if let sodium, sodium > 0.6 { score -= 5 }

        // Adjust for good fiber
        if let fiber, fiber > 3 { score += 5 }

        // Adjust for good protein
        if protein > 10 { score += 5 }

        return max(0, min(100, score))
    }

    var healthRating: HealthRating {
        switch healthScore {
        case 70...: return .good
        case 50..<70: return .ok
        case 30..<50: return .poor
        default: return .bad
        }
    }

    // MARK: - Conversion to FoodAnalysisResult (for meal logging)

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
            servingSize: servingSize,
            confidence: 90,
            brand: brand,
            barcode: barcode,
            imageURL: imageURL
        )
    }
}

// MARK: - Supporting Types

struct NutrientLevels: Sendable, Equatable {
    let fat: NutrientLevel?
    let saturatedFat: NutrientLevel?
    let sugars: NutrientLevel?
    let salt: NutrientLevel?
}

enum NutrientLevel: String, Sendable {
    case low, moderate, high

    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .orange
        case .high: return .red
        }
    }

    var label: String {
        rawValue.capitalized
    }
}

enum HealthRating: String, Sendable {
    case good, ok, poor, bad

    var color: Color {
        switch self {
        case .good: return .green
        case .ok: return .yellow
        case .poor: return .orange
        case .bad: return .red
        }
    }

    var label: String {
        switch self {
        case .good: return "Good"
        case .ok: return "OK"
        case .poor: return "Poor"
        case .bad: return "Bad"
        }
    }
}
