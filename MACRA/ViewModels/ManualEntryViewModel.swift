import Foundation
import SwiftData

@Observable
@MainActor
final class ManualEntryViewModel {
    var foodName = ""
    var caloriesText = ""
    var proteinText = ""
    var carbsText = ""
    var fatText = ""
    var servingSize = ""
    var selectedMealType: MealType = .lunch
    var didSave = false
    var errorMessage: String?

    private let mealRepository: MealRepositoryProtocol

    convenience init(modelContainer: ModelContainer) {
        self.init(mealRepository: MealRepository(modelContainer: modelContainer))
    }

    init(mealRepository: MealRepositoryProtocol) {
        self.mealRepository = mealRepository
    }

    var canSave: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(caloriesText) ?? 0) > 0
    }

    func save() async {
        guard canSave else { return }

        let item = NewMealItem(
            foodName: foodName.trimmingCharacters(in: .whitespaces),
            calories: Double(caloriesText) ?? 0,
            protein: Double(proteinText) ?? 0,
            carbs: Double(carbsText) ?? 0,
            fat: Double(fatText) ?? 0,
            servingSize: servingSize.isEmpty ? nil : servingSize,
            entryMethod: .manual
        )

        do {
            try await mealRepository.addMeal(
                date: Date(),
                mealType: selectedMealType,
                items: [item]
            )
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
