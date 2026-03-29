import Foundation
import SwiftData

// MARK: - QuickMealFood (Codable value type for embedding in QuickMeal)

struct QuickMealFood: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String?
    var quantity: Double

    init(
        id: UUID = UUID(),
        name: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingSize: String? = nil,
        quantity: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.quantity = quantity
    }
}

// MARK: - QuickMeal (SwiftData persistent model)

@Model
final class QuickMeal {
    @Attribute(.unique) var id: UUID
    var userId: String = ""
    var name: String
    var foodItems: [QuickMealFood]
    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var typicalHour: Int
    var logCount: Int
    var lastLogged: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        foodItems: [QuickMealFood],
        totalCalories: Double,
        totalProtein: Double,
        totalCarbs: Double,
        totalFat: Double,
        typicalHour: Int,
        logCount: Int = 1,
        lastLogged: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.foodItems = foodItems
        self.totalCalories = totalCalories
        self.totalProtein = totalProtein
        self.totalCarbs = totalCarbs
        self.totalFat = totalFat
        self.typicalHour = typicalHour
        self.logCount = logCount
        self.lastLogged = lastLogged
        self.createdAt = createdAt
    }
}
