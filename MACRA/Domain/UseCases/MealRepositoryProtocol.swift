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
}

struct NewMealItem: Sendable {
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String?
    let entryMethod: EntryMethod

    init(
        foodName: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingSize: String? = nil,
        entryMethod: EntryMethod = .manual
    ) {
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.entryMethod = entryMethod
    }
}
