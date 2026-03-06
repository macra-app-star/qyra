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
            let results = try await GeminiService.shared.analyzeFoodPhoto(imageData: imageData)
            items = results
            if items.isEmpty {
                errorMessage = "No food items detected. Try retaking the photo."
            }
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
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
