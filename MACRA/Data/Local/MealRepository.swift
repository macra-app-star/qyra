import Foundation
import SwiftData

extension Notification.Name {
    static let mealLogged = Notification.Name("mealLogged")
    static let exerciseLogged = Notification.Name("exerciseLogged")
    static let waterLogged = Notification.Name("waterLogged")
    static let caffeineLogged = Notification.Name("caffeineLogged")
    static let weightLogged = Notification.Name("weightLogged")
    static let appBecameActive = Notification.Name("appBecameActive")
    static let openFoodDatabase = Notification.Name("openFoodDatabase")
}

@ModelActor
actor MealRepository: MealRepositoryProtocol {

    func fetchDailySummary(for date: Date) async throws -> DailySummary {
        let startOfDay = Calendar.current.startOfDay(for: date)
        guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return DailySummary(date: startOfDay, totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0, totalFiber: 0, totalSugar: 0, totalSodium: 0, meals: [])
        }

        let descriptor = FetchDescriptor<MealLog>(
            predicate: #Predicate<MealLog> { meal in
                meal.date >= startOfDay && meal.date < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt)]
        )

        let mealLogs = try modelContext.fetch(descriptor)

        let meals = mealLogs.map { log in
            MealSummary(
                id: log.id,
                mealType: log.mealType,
                date: log.createdAt,  // Use actual creation time, not start-of-day
                items: log.items.map { item in
                    MealItemSummary(
                        id: item.id,
                        foodName: item.foodName,
                        calories: item.calories,
                        protein: item.protein,
                        carbs: item.carbs,
                        fat: item.fat,
                        fiber: item.fiber,
                        sugar: item.sugar,
                        sodium: item.sodium,
                        servingSize: item.servingSize,
                        entryMethod: item.entryMethod ?? .manual
                    )
                }
            )
        }

        return DailySummary(
            date: startOfDay,
            totalCalories: meals.reduce(0) { $0 + $1.totalCalories },
            totalProtein: meals.reduce(0) { $0 + $1.totalProtein },
            totalCarbs: meals.reduce(0) { $0 + $1.totalCarbs },
            totalFat: meals.reduce(0) { $0 + $1.totalFat },
            totalFiber: meals.reduce(0) { $0 + $1.totalFiber },
            totalSugar: meals.reduce(0) { $0 + $1.totalSugar },
            totalSodium: meals.reduce(0) { $0 + $1.totalSodium },
            meals: meals
        )
    }

    func addMeal(date: Date, mealType: MealType, items: [NewMealItem]) async throws {
        let mealLog = MealLog(date: date, mealType: mealType)
        modelContext.insert(mealLog)

        for item in items {
            let mealItem = MealItem(
                foodName: item.foodName,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                fiber: item.fiber,
                sugar: item.sugar,
                sodium: item.sodium,
                servingSize: item.servingSize,
                confidenceScore: item.confidenceScore,
                entryMethod: item.entryMethod,
                barcode: item.barcode,
                imageURL: item.imageURL,
                userVerified: item.entryMethod == .manual,
                isFavorite: item.isFavorite
            )
            mealItem.mealLog = mealLog
            mealLog.items.append(mealItem)
        }

        let syncRecord = SyncRecord(
            entityType: "MealLog",
            entityId: mealLog.id,
            operation: .insert
        )
        modelContext.insert(syncRecord)

        try modelContext.save()

        // Aggregate nutrition totals for HealthKit write-back
        let totalCalories = items.reduce(0.0) { $0 + $1.calories }
        let totalProtein = items.reduce(0.0) { $0 + $1.protein }
        let totalCarbs = items.reduce(0.0) { $0 + $1.carbs }
        let totalFat = items.reduce(0.0) { $0 + $1.fat }

        Task { @MainActor in
            NotificationCenter.default.post(name: .mealLogged, object: nil)
            await HealthKitService.shared.saveNutrition(
                calories: totalCalories,
                protein: totalProtein,
                carbs: totalCarbs,
                fat: totalFat,
                date: date
            )
        }
    }

    func deleteMeal(id: UUID) async throws {
        let descriptor = FetchDescriptor<MealLog>(
            predicate: #Predicate<MealLog> { $0.id == id }
        )
        guard let mealLog = try modelContext.fetch(descriptor).first else { return }

        let syncRecord = SyncRecord(
            entityType: "MealLog",
            entityId: id,
            operation: .delete
        )
        modelContext.insert(syncRecord)

        modelContext.delete(mealLog)
        try modelContext.save()
    }

    func addItemToMeal(mealId: UUID, item: NewMealItem) async throws {
        let descriptor = FetchDescriptor<MealLog>(
            predicate: #Predicate<MealLog> { $0.id == mealId }
        )
        guard let mealLog = try modelContext.fetch(descriptor).first else { return }

        let mealItem = MealItem(
            foodName: item.foodName,
            calories: item.calories,
            protein: item.protein,
            carbs: item.carbs,
            fat: item.fat,
            fiber: item.fiber,
            sugar: item.sugar,
            sodium: item.sodium,
            servingSize: item.servingSize,
            confidenceScore: item.confidenceScore,
            entryMethod: item.entryMethod,
            barcode: item.barcode,
            imageURL: item.imageURL,
            userVerified: item.entryMethod == .manual,
            isFavorite: item.isFavorite
        )
        mealItem.mealLog = mealLog
        mealLog.items.append(mealItem)

        let syncRecord = SyncRecord(
            entityType: "MealItem",
            entityId: mealItem.id,
            operation: .insert
        )
        modelContext.insert(syncRecord)
        try modelContext.save()
    }

    func deleteMealItem(id: UUID) async throws {
        let descriptor = FetchDescriptor<MealItem>(
            predicate: #Predicate<MealItem> { $0.id == id }
        )
        guard let item = try modelContext.fetch(descriptor).first else { return }

        let syncRecord = SyncRecord(
            entityType: "MealItem",
            entityId: id,
            operation: .delete
        )
        modelContext.insert(syncRecord)

        modelContext.delete(item)
        try modelContext.save()
    }
}
