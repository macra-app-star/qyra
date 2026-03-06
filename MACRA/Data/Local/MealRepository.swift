import Foundation
import SwiftData

@ModelActor
actor MealRepository: MealRepositoryProtocol {

    func fetchDailySummary(for date: Date) async throws -> DailySummary {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

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
                date: log.date,
                items: log.items.map { item in
                    MealItemSummary(
                        id: item.id,
                        foodName: item.foodName,
                        calories: item.calories,
                        protein: item.protein,
                        carbs: item.carbs,
                        fat: item.fat,
                        servingSize: item.servingSize,
                        entryMethod: item.entryMethod
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
                userVerified: item.entryMethod == .manual
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
            userVerified: item.entryMethod == .manual
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
