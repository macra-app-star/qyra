import Foundation
import CoreML
import Vision
import UIKit

// INTEGRATED FROM: AI4Food-NutritionDB taxonomy, Nutrition5k
// On-device food classification using CoreML Vision framework.
// Gracefully degrades if no .mlmodel is bundled (falls back to Gemini).

actor FoodClassificationService {
    static let shared = FoodClassificationService()

    private var classificationModel: VNCoreMLModel?
    private var isModelLoaded = false

    // MARK: - Model Loading

    /// Attempt to load the bundled FoodClassifier.mlmodel
    /// Returns false if model is not bundled (user hasn't trained it yet)
    func loadModel() -> Bool {
        guard !isModelLoaded else { return classificationModel != nil }
        isModelLoaded = true

        // Try to load the compiled model from the app bundle
        guard let modelURL = Bundle.main.url(forResource: "FoodClassifier", withExtension: "mlmodelc") else {
            // No model bundled — this is expected until user trains one
            return false
        }

        do {
            let mlModel = try MLModel(contentsOf: modelURL)
            classificationModel = try VNCoreMLModel(for: mlModel)
            return true
        } catch {
            return false
        }
    }

    /// Whether local classification is available
    var isAvailable: Bool {
        loadModel()
    }

    // MARK: - Classification

    /// Classify a food image on-device. Returns top predictions with confidence.
    func classify(image: CGImage) async throws -> [FoodPrediction] {
        guard let model = classificationModel else {
            throw ClassificationError.modelNotLoaded
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNClassificationObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let predictions = results.prefix(5).map { observation in
                    FoodPrediction(
                        label: observation.identifier,
                        confidence: Double(observation.confidence)
                    )
                }

                continuation.resume(returning: predictions)
            }

            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Classify from UIImage convenience
    func classify(uiImage: UIImage) async throws -> [FoodPrediction] {
        guard let cgImage = uiImage.cgImage else {
            throw ClassificationError.invalidImage
        }
        return try await classify(image: cgImage)
    }

    // MARK: - Errors

    enum ClassificationError: LocalizedError {
        case modelNotLoaded
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded: return "Food classification model not available. Train and bundle FoodClassifier.mlmodel."
            case .invalidImage: return "Could not process the image for classification."
            }
        }
    }
}

// MARK: - Prediction Result

struct FoodPrediction: Sendable, Identifiable {
    let id = UUID()
    let label: String
    let confidence: Double

    var displayName: String {
        label.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var confidencePercent: Int {
        Int(confidence * 100)
    }
}
