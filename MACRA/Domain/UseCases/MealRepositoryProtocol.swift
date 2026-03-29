import Foundation

protocol MealRepositoryProtocol: Sendable {
    func fetchDailySummary(for date: Date) async throws -> DailySummary
    func addMeal(
        date: Date,
        mealType: MealType,
        items: [NewMealItem]
    ) async throws
    func deleteMeal(id: UUID) async throws
    func deleteMealItem(id: UUID) async throws
    func addItemToMeal(mealId: UUID, item: NewMealItem) async throws
}

struct NewMealItem: Sendable {
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let sugar: Double?
    let sodium: Double?
    let servingSize: String?
    let entryMethod: EntryMethod
    let confidenceScore: Int?
    let barcode: String?
    let imageURL: String?
    let isFavorite: Bool

    init(
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        servingSize: String? = nil,
        entryMethod: EntryMethod = .manual,
        confidenceScore: Int? = nil,
        barcode: String? = nil,
        imageURL: String? = nil,
        isFavorite: Bool = false
    ) {
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
        self.entryMethod = entryMethod
        self.confidenceScore = confidenceScore
        self.barcode = barcode
        self.imageURL = imageURL
        self.isFavorite = isFavorite
    }
}
