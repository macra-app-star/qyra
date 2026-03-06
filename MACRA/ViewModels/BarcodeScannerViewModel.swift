import Foundation
import SwiftData

@Observable
@MainActor
final class BarcodeScannerViewModel {
    var scannedBarcode: String?
    var product: FoodAnalysisResult?
    var isLookingUp = false
    var errorMessage: String?
    var quantity: Int = 1
    var selectedMealType: MealType = .lunch
    var didSave = false
    var isScanning = true

    private let mealRepository: MealRepositoryProtocol
    private var processedBarcodes: Set<String> = []

    convenience init(modelContainer: ModelContainer) {
        self.init(mealRepository: MealRepository(modelContainer: modelContainer))
    }

    init(mealRepository: MealRepositoryProtocol) {
        self.mealRepository = mealRepository
        autoSelectMealType()
    }

    // MARK: - Barcode Detection

    func onBarcodeDetected(_ barcode: String) async {
        guard !processedBarcodes.contains(barcode), !isLookingUp else { return }

        processedBarcodes.insert(barcode)
        scannedBarcode = barcode
        isLookingUp = true
        isScanning = false
        errorMessage = nil

        do {
            if let result = try await OpenFoodFactsService.shared.lookupBarcode(barcode) {
                product = result
            } else {
                // Fallback: ask Gemini to identify by barcode
                let results = try await GeminiService.shared.parseNaturalLanguage(
                    text: "Product with barcode \(barcode)"
                )
                if let first = results.first {
                    product = FoodAnalysisResult(
                        name: first.name,
                        calories: first.calories,
                        protein: first.protein,
                        carbs: first.carbs,
                        fat: first.fat,
                        servingSize: first.servingSize,
                        confidence: 50,
                        barcode: barcode
                    )
                } else {
                    errorMessage = "Product not found. Try searching manually."
                }
            }
        } catch {
            errorMessage = "Lookup failed: \(error.localizedDescription)"
        }

        isLookingUp = false
    }

    // MARK: - Logging

    func logProduct() async {
        guard var item = product else { return }

        // Scale by quantity
        if quantity > 1 {
            item = FoodAnalysisResult(
                name: item.name,
                calories: item.calories * Double(quantity),
                protein: item.protein * Double(quantity),
                carbs: item.carbs * Double(quantity),
                fat: item.fat * Double(quantity),
                fiber: item.fiber.map { $0 * Double(quantity) },
                sugar: item.sugar.map { $0 * Double(quantity) },
                sodium: item.sodium.map { $0 * Double(quantity) },
                servingSize: quantity > 1 ? "\(quantity)x \(item.servingSize ?? "serving")" : item.servingSize,
                confidence: item.confidence,
                brand: item.brand,
                barcode: item.barcode,
                imageURL: item.imageURL
            )
        }

        let newItem = item.toNewMealItem(entryMethod: .barcode)

        do {
            try await mealRepository.addMeal(
                date: Date(),
                mealType: selectedMealType,
                items: [newItem]
            )
            didSave = true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func rescan() {
        product = nil
        scannedBarcode = nil
        errorMessage = nil
        isScanning = true
        processedBarcodes.removeAll()
    }

    private func autoSelectMealType() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11: selectedMealType = .breakfast
        case 11..<15: selectedMealType = .lunch
        case 15..<21: selectedMealType = .dinner
        default: selectedMealType = .snack
        }
    }
}
