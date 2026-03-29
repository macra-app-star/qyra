import Foundation
import SwiftData

@Observable
@MainActor
final class QuickMealDetector {

    // MARK: - Pattern Detection

    /// Checks if the newly logged meal forms a recurring pattern with recent meals.
    /// If the same food names appear 3+ times at a similar hour (within 1 hour) on
    /// different days over the last 14 days, a QuickMeal is created or updated.
    func checkForPattern(
        newMeal: MealLog,
        recentMeals: [MealLog],
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let newHour = calendar.component(.hour, from: newMeal.createdAt)
        let newFoodKey = foodKey(from: newMeal.items)

        guard !newFoodKey.isEmpty else { return }

        // Group recent meals that share the same food key and similar time
        var matchingDays: Set<Date> = []

        for meal in recentMeals {
            // Skip meals from the same day as the new meal
            let mealDay = calendar.startOfDay(for: meal.createdAt)
            let newDay = calendar.startOfDay(for: newMeal.createdAt)
            guard mealDay != newDay else { continue }

            let mealHour = calendar.component(.hour, from: meal.createdAt)
            let hourDiff = abs(mealHour - newHour)

            guard hourDiff <= 1 else { continue }

            let mealKey = foodKey(from: meal.items)
            guard mealKey == newFoodKey else { continue }

            matchingDays.insert(mealDay)
        }

        // Include today as a matching day
        matchingDays.insert(calendar.startOfDay(for: newMeal.createdAt))

        // Need 3+ occurrences on different days to qualify
        guard matchingDays.count >= 3 else { return }

        // Build or update the QuickMeal
        let quickMealFoods = newMeal.items.map { item in
            QuickMealFood(
                name: item.foodName,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                servingSize: item.servingSize,
                quantity: 1.0
            )
        }

        let generatedName = generateMealName(
            items: newMeal.items,
            hour: newHour
        )

        // Check if a QuickMeal with this food key already exists
        let existingDescriptor = FetchDescriptor<QuickMeal>()
        let existingQuickMeals = (try? context.fetch(existingDescriptor)) ?? []

        if let existing = existingQuickMeals.first(where: { quickMealFoodKey(from: $0.foodItems) == newFoodKey }) {
            // Update existing QuickMeal
            existing.logCount = matchingDays.count
            existing.lastLogged = .now
            existing.totalCalories = quickMealFoods.reduce(0) { $0 + $1.calories }
            existing.totalProtein = quickMealFoods.reduce(0) { $0 + $1.protein }
            existing.totalCarbs = quickMealFoods.reduce(0) { $0 + $1.carbs }
            existing.totalFat = quickMealFoods.reduce(0) { $0 + $1.fat }
            existing.foodItems = quickMealFoods
        } else {
            // Create new QuickMeal
            let quickMeal = QuickMeal(
                name: generatedName,
                foodItems: quickMealFoods,
                totalCalories: quickMealFoods.reduce(0) { $0 + $1.calories },
                totalProtein: quickMealFoods.reduce(0) { $0 + $1.protein },
                totalCarbs: quickMealFoods.reduce(0) { $0 + $1.carbs },
                totalFat: quickMealFoods.reduce(0) { $0 + $1.fat },
                typicalHour: newHour,
                logCount: matchingDays.count,
                lastLogged: .now
            )
            context.insert(quickMeal)
        }

        try? context.save()
    }

    // MARK: - Time-Relevant Filtering

    /// Returns QuickMeals whose typical hour is within 3 hours of the current time,
    /// sorted by logCount descending (most frequently logged first).
    func timeRelevantQuickMeals(from quickMeals: [QuickMeal]) -> [QuickMeal] {
        let currentHour = Calendar.current.component(.hour, from: Date())

        return quickMeals
            .filter { meal in
                let diff = abs(meal.typicalHour - currentHour)
                let wrappedDiff = min(diff, 24 - diff)
                return wrappedDiff <= 3
            }
            .sorted { $0.logCount > $1.logCount }
    }

    // MARK: - Private Helpers

    /// Creates a normalized key from a meal's items for comparison.
    /// Lowercased food names, sorted alphabetically, joined by "+".
    private func foodKey(from items: [MealItem]) -> String {
        items
            .map { $0.foodName.lowercased().trimmingCharacters(in: .whitespaces) }
            .sorted()
            .joined(separator: "+")
    }

    /// Creates a normalized key from QuickMealFood items for comparison.
    private func quickMealFoodKey(from items: [QuickMealFood]) -> String {
        items
            .map { $0.name.lowercased().trimmingCharacters(in: .whitespaces) }
            .sorted()
            .joined(separator: "+")
    }

    /// Generates a human-readable meal name like "Morning eggs & toast".
    private func generateMealName(items: [MealItem], hour: Int) -> String {
        let timePrefix: String
        switch hour {
        case 5..<11: timePrefix = "Morning"
        case 11..<14: timePrefix = "Midday"
        case 14..<17: timePrefix = "Afternoon"
        case 17..<21: timePrefix = "Evening"
        default: timePrefix = "Late night"
        }

        let foodNames = items.map { shortenFoodName($0.foodName) }

        let foodDescription: String
        switch foodNames.count {
        case 0:
            foodDescription = "meal"
        case 1:
            foodDescription = foodNames[0]
        case 2:
            foodDescription = "\(foodNames[0]) & \(foodNames[1])"
        default:
            let first = foodNames.prefix(2).joined(separator: ", ")
            foodDescription = "\(first) + \(foodNames.count - 2) more"
        }

        return "\(timePrefix) \(foodDescription)"
    }

    /// Shortens a food name to a concise label (first 2-3 words).
    private func shortenFoodName(_ name: String) -> String {
        let words = name.split(separator: " ").prefix(3)
        return words.joined(separator: " ").lowercased()
    }
}
