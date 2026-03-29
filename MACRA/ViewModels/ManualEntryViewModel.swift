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
    var fiberText = ""
    var sugarText = ""
    var sodiumText = ""
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
        autoSelectMealType()
    }

    private func autoSelectMealType() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<10: selectedMealType = .breakfast
        case 10..<14: selectedMealType = .lunch
        case 14..<17: selectedMealType = .snack
        default: selectedMealType = .dinner
        }
    }

    var canSave: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(caloriesText) ?? 0) > 0
            && validationWarning == nil
    }

    var validationWarning: String? {
        let cal = Double(caloriesText) ?? 0
        if cal > 10_000 { return "Calories cannot exceed 10,000" }

        let protein = Double(proteinText) ?? 0
        let carbs = Double(carbsText) ?? 0
        let fat = Double(fatText) ?? 0
        let fiber = Double(fiberText) ?? 0
        let sugar = Double(sugarText) ?? 0
        let sodium = Double(sodiumText) ?? 0

        if protein > 1000 { return "Protein cannot exceed 1,000g" }
        if carbs > 1000 { return "Carbs cannot exceed 1,000g" }
        if fat > 1000 { return "Fat cannot exceed 1,000g" }
        if fiber > 1000 { return "Fiber cannot exceed 1,000g" }
        if sugar > 1000 { return "Sugar cannot exceed 1,000g" }
        if sodium > 10_000 { return "Sodium cannot exceed 10,000mg" }

        return nil
    }

    func save() async {
        guard canSave else { return }

        let fiber = Double(fiberText)
        let sugar = Double(sugarText)
        let sodium = Double(sodiumText)

        let item = NewMealItem(
            foodName: foodName.trimmingCharacters(in: .whitespaces),
            calories: max(0, Double(caloriesText) ?? 0),
            protein: max(0, Double(proteinText) ?? 0),
            carbs: max(0, Double(carbsText) ?? 0),
            fat: max(0, Double(fatText) ?? 0),
            fiber: fiber != nil && fiber! > 0 ? fiber : nil,
            sugar: sugar != nil && sugar! > 0 ? sugar : nil,
            sodium: sodium != nil && sodium! > 0 ? sodium : nil,
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
