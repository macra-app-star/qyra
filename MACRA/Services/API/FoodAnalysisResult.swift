import Foundation

struct FoodAnalysisResult: Sendable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var servingSize: String?
    var confidence: Int // 0-100
    var brand: String?
    var barcode: String?
    var imageURL: String?
    var explanation: String?
    var assumptions: [String]?
    var needsManualEntry: Bool

    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        servingSize: String? = nil,
        confidence: Int = 80,
        brand: String? = nil,
        barcode: String? = nil,
        imageURL: String? = nil,
        explanation: String? = nil,
        assumptions: [String]? = nil,
        needsManualEntry: Bool = false
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
        self.confidence = confidence
        self.brand = brand
        self.barcode = barcode
        self.imageURL = imageURL
        self.explanation = explanation
        self.assumptions = assumptions
        self.needsManualEntry = needsManualEntry
    }

    // Food verdict based on macro balance
    var verdict: (String, String) { // (label, systemColor)
        let proteinRatio = protein * 4 / max(calories, 1)
        if proteinRatio > 0.3 { return ("High protein", "green") }
        if calories > 500 && proteinRatio < 0.15 { return ("Low protein density", "orange") }
        if carbs > 60 { return ("High carb load", "orange") }
        if fat > 30 && calories > 400 { return ("Calorie dense", "orange") }
        if calories < 200 && protein > 15 { return ("Lean choice", "green") }
        return ("Balanced", "blue")
    }

    func toNewMealItem(entryMethod: EntryMethod, isFavorite: Bool = false) -> NewMealItem {
        NewMealItem(
            foodName: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            servingSize: servingSize,
            entryMethod: entryMethod,
            confidenceScore: confidence,
            barcode: barcode,
            imageURL: imageURL,
            isFavorite: isFavorite
        )
    }
}
