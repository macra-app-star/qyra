import Foundation
import SwiftData

@Observable
@MainActor
final class PhotoAnalysisViewModel {
    var items: [FoodAnalysisResult] = []
    var isAnalyzing = false
    var errorMessage: String?
    var selectedMealType: MealType = .lunch
    var didSave = false

    private let mealRepository: MealRepositoryProtocol

    convenience init(modelContainer: ModelContainer) {
        self.init(mealRepository: MealRepository(modelContainer: modelContainer))
    }

    init(mealRepository: MealRepositoryProtocol) {
        self.mealRepository = mealRepository
        autoSelectMealType()
    }

    // MARK: - Analysis

    func analyze(imageData: Data) async {
        isAnalyzing = true
        errorMessage = nil

        do {
            // Use hybrid pipeline: CoreML (offline) → local DB → Gemini (cloud)
            let results = try await FoodAnalysisPipeline.shared.analyze(imageData: imageData)
            items = results
            if items.isEmpty {
                errorMessage = "No food items detected. Try retaking the photo."
            }
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    // MARK: - Serving Size Adjustment

    /// Scale nutrition values for a specific item by serving multiplier
    func adjustServing(at index: Int, multiplier: Double) {
        guard items.indices.contains(index) else { return }
        let item = items[index]
        items[index] = FoodAnalysisResult(
            name: item.name,
            calories: item.calories * multiplier,
            protein: item.protein * multiplier,
            carbs: item.carbs * multiplier,
            fat: item.fat * multiplier,
            fiber: item.fiber.map { $0 * multiplier },
            sugar: item.sugar.map { $0 * multiplier },
            sodium: item.sodium.map { $0 * multiplier },
            servingSize: item.servingSize,
            confidence: item.confidence,
            brand: item.brand,
            barcode: item.barcode,
            imageURL: item.imageURL
        )
    }

    /// Update a specific item's values directly (for manual editing)
    func updateItem(at index: Int, name: String? = nil, calories: Double? = nil,
                    protein: Double? = nil, carbs: Double? = nil, fat: Double? = nil,
                    servingSize: String? = nil) {
        guard items.indices.contains(index) else { return }
        let item = items[index]
        items[index] = FoodAnalysisResult(
            name: name ?? item.name,
            calories: calories ?? item.calories,
            protein: protein ?? item.protein,
            carbs: carbs ?? item.carbs,
            fat: fat ?? item.fat,
            fiber: item.fiber,
            sugar: item.sugar,
            sodium: item.sodium,
            servingSize: servingSize ?? item.servingSize,
            confidence: item.confidence,
            brand: item.brand,
            barcode: item.barcode,
            imageURL: item.imageURL
        )
    }

    // MARK: - Editing

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
    }

    func addEmptyItem() {
        items.append(FoodAnalysisResult(
            name: "",
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            confidence: 0
        ))
    }

    // MARK: - Logging

    var canLog: Bool {
        !items.isEmpty && items.allSatisfy { !$0.name.isEmpty && $0.calories > 0 }
    }

    func logMeal() async {
        guard canLog else { return }

        let newItems = items.map { $0.toNewMealItem(entryMethod: .photo) }

        do {
            try await mealRepository.addMeal(
                date: Date(),
                mealType: selectedMealType,
                items: newItems
            )
            didSave = true
            AnalyticsService.shared.track(.mealLogged, properties: [
                "entry_method": "photo",
                "meal_type": selectedMealType.rawValue,
                "item_count": String(newItems.count)
            ])
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    private func autoSelectMealType() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: selectedMealType = .breakfast
        case 11..<15: selectedMealType = .lunch
        case 15..<21: selectedMealType = .dinner
        default: selectedMealType = .snack
        }
    }

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
}
