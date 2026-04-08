import SwiftUI
import CoreML

@MainActor
final class MLModelService: ObservableObject {
    static let shared = MLModelService()

    @Published var isModelAvailable: Bool = false

    private init() {
        checkModelAvailability()
    }

    func checkModelAvailability() {
        if Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodelc") != nil {
            isModelAvailable = true
        } else {
            isModelAvailable = false
            #if DEBUG
            print("[MLModelService] CoreML model not bundled — camera classification disabled, falling back to cloud AI")
            #endif
        }
    }
}
