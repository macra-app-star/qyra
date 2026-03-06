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
        imageURL: String? = nil
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
    }

    func toNewMealItem(entryMethod: EntryMethod) -> NewMealItem {
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
            imageURL: imageURL
        )
    }
}
