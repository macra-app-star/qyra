import Foundation

struct DailySummary: Sendable, Equatable {
    let date: Date
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbs: Double
    let totalFat: Double
    let meals: [MealSummary]
}

struct MealSummary: Sendable, Equatable, Identifiable {
    let id: UUID
    let mealType: MealType
    let date: Date
    let items: [MealItemSummary]

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }

    var displayDetail: String {
        items.map(\.foodName).joined(separator: ", ")
    }
}

struct MealItemSummary: Sendable, Equatable, Identifiable {
    let id: UUID
    let foodName: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let servingSize: String?
    let entryMethod: EntryMethod
}

struct MacroGoalSnapshot: Sendable, Equatable {
    let dailyCalorieGoal: Int
    let dailyProteinGoal: Int
    let dailyCarbGoal: Int
    let dailyFatGoal: Int
    let activityLevel: ActivityLevel
    let goalType: GoalType

    static let `default` = MacroGoalSnapshot(
        dailyCalorieGoal: 2000,
        dailyProteinGoal: 150,
        dailyCarbGoal: 200,
        dailyFatGoal: 65,
        activityLevel: .moderatelyActive,
        goalType: .maintain
    )
}

struct DayReconciliation: Sendable, Equatable {
    let summary: DailySummary
    let goal: MacroGoalSnapshot
}
