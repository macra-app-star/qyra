import Foundation
import SwiftData

// INTEGRATED FROM: Open Food Facts, USDA FoodData Central
// Local SwiftData cache for food products.
// Provides offline-first barcode lookup and text search.

@ModelActor
actor FoodProductRepository {

    // MARK: - Barcode Lookup

    /// Find a cached product by barcode
    func findByBarcode(_ barcode: String) -> FoodProduct? {
        let descriptor = FetchDescriptor<FoodProduct>(
            predicate: #Predicate { $0.barcode == barcode }
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Text Search

    /// Search cached products by name (case-insensitive prefix match)
    func search(query: String, limit: Int = 25) -> [FoodProduct] {
        let lowered = query.lowercased()
        let descriptor = FetchDescriptor<FoodProduct>(
            predicate: #Predicate { $0.searchName.contains(lowered) },
            sortBy: [SortDescriptor(\.lastUpdated, order: .reverse)]
        )
        var limited = descriptor
        limited.fetchLimit = limit
        return (try? modelContext.fetch(limited)) ?? []
    }

    // MARK: - Upsert

    /// Insert or update a food product in the local cache
    func upsert(_ product: FoodProduct) {
        // Check if product already exists
        if let existing = findByBarcode(product.barcode) {
            existing.name = product.name
            existing.brands = product.brands
            existing.categories = product.categories
            existing.imageURL = product.imageURL
            existing.caloriesPer100g = product.caloriesPer100g
            existing.proteinPer100g = product.proteinPer100g
            existing.carbsPer100g = product.carbsPer100g
            existing.fatPer100g = product.fatPer100g
            existing.fiberPer100g = product.fiberPer100g
            existing.sugarPer100g = product.sugarPer100g
            existing.sodiumPer100g = product.sodiumPer100g
            existing.servingSize = product.servingSize
            existing.servingSizeGrams = product.servingSizeGrams
            existing.nutriScore = product.nutriScore
            existing.novaGroup = product.novaGroup
            existing.allergens = product.allergens
            existing.ingredients = product.ingredients
            existing.source = product.source
            existing.lastUpdated = .now
            existing.searchName = product.name.lowercased()
        } else {
            modelContext.insert(product)
        }

        try? modelContext.save()
    }

    // MARK: - Batch Import

    /// Import an array of products in batches (for USDA bulk import)
    func batchImport(_ products: [FoodProduct], batchSize: Int = 500) -> Int {
        var imported = 0
        for product in products {
            modelContext.insert(product)
            imported += 1
            if imported % batchSize == 0 {
                try? modelContext.save()
            }
        }
        try? modelContext.save()
        return imported
    }

    // MARK: - Stats

    /// Count total cached products
    func totalCount() -> Int {
        let descriptor = FetchDescriptor<FoodProduct>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    /// Count products by source
    func countBySource(_ source: String) -> Int {
        let descriptor = FetchDescriptor<FoodProduct>(
            predicate: #Predicate { $0.source == source }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }
}
