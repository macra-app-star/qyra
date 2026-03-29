import Foundation
import UIKit
import SwiftData

// INTEGRATED FROM: Nutrition5k + AI4Food-NutritionDB + Open Food Facts + Gemini
// Hybrid food analysis pipeline:
//   1. CoreML classifier (offline, fast) → food label
//   2. Local FoodProduct DB lookup → nutrition data
//   3. Gemini API refinement (online, optional) → higher accuracy
//
// Works fully offline with CoreML + local cache.
// Falls back to Gemini-only when CoreML model isn't bundled.

@MainActor
final class FoodAnalysisPipeline: ObservableObject {
    static let shared = FoodAnalysisPipeline()

    @Published var analysisMode: AnalysisMode = .auto

    private let classifier = FoodClassificationService.shared
    private let geminiService = GeminiService.shared
    private var modelContainer: ModelContainer?

    enum AnalysisMode: String, CaseIterable {
        case auto       // CoreML first, Gemini if needed
        case offlineOnly // CoreML + local DB only
        case cloudOnly   // Gemini only (current behavior)
    }

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Analyze Food Photo

    /// Analyze a food photo using the best available method
    func analyze(imageData: Data) async throws -> [FoodAnalysisResult] {
        switch analysisMode {
        case .offlineOnly:
            return try await analyzeOffline(imageData: imageData)
        case .cloudOnly:
            return try await analyzeCloud(imageData: imageData)
        case .auto:
            return try await analyzeHybrid(imageData: imageData)
        }
    }

    // MARK: - Hybrid Pipeline (best quality)

    private func analyzeHybrid(imageData: Data) async throws -> [FoodAnalysisResult] {
        // Try CoreML first (fast, free, offline)
        if await classifier.isAvailable,
           let uiImage = UIImage(data: imageData),
           let predictions = try? await classifier.classify(uiImage: uiImage),
           !predictions.isEmpty {

            // Got local predictions — enrich with nutrition data
            let results = await lookupNutrition(for: predictions)

            // If we got decent results locally, use them
            if !results.isEmpty, results.first?.confidence ?? 0 >= 70 {
                return results
            }

            // Otherwise, refine with Gemini for higher accuracy
            if let cloudResults = try? await analyzeCloud(imageData: imageData) {
                return cloudResults
            }

            // Gemini failed — return local results as fallback
            return results
        }

        // No CoreML model — use Gemini directly
        return try await analyzeCloud(imageData: imageData)
    }

    // MARK: - Offline Pipeline (no network)

    private func analyzeOffline(imageData: Data) async throws -> [FoodAnalysisResult] {
        guard await classifier.isAvailable else {
            throw PipelineError.noOfflineModel
        }

        guard let uiImage = UIImage(data: imageData) else {
            throw PipelineError.invalidImage
        }

        let predictions = try await classifier.classify(uiImage: uiImage)
        let results = await lookupNutrition(for: predictions)

        if results.isEmpty {
            // Model classified but no nutrition data in cache
            return predictions.map { prediction in
                FoodAnalysisResult(
                    name: prediction.displayName,
                    calories: 0,
                    protein: 0,
                    carbs: 0,
                    fat: 0,
                    confidence: prediction.confidencePercent
                )
            }
        }

        return results
    }

    // MARK: - Cloud Pipeline (Gemini)

    private func analyzeCloud(imageData: Data) async throws -> [FoodAnalysisResult] {
        try await geminiService.analyzeFoodPhoto(imageData: imageData)
    }

    // MARK: - Nutrition Lookup

    /// Look up nutrition data for classified food labels in local cache
    private func lookupNutrition(for predictions: [FoodPrediction]) async -> [FoodAnalysisResult] {
        guard let container = modelContainer else {
            return predictions.map { p in
                FoodAnalysisResult(
                    name: p.displayName,
                    calories: 0, protein: 0, carbs: 0, fat: 0,
                    confidence: p.confidencePercent
                )
            }
        }

        let repo = FoodProductRepository(modelContainer: container)
        var results: [FoodAnalysisResult] = []

        for prediction in predictions.prefix(3) {
            let cached = await repo.search(query: prediction.label, limit: 1)
            if let product = cached.first {
                let dbResult = product.toFoodAnalysisResult()
                // Blend confidence from classifier and DB match
                let result = FoodAnalysisResult(
                    name: prediction.displayName,
                    calories: dbResult.calories,
                    protein: dbResult.protein,
                    carbs: dbResult.carbs,
                    fat: dbResult.fat,
                    fiber: dbResult.fiber,
                    sugar: dbResult.sugar,
                    sodium: dbResult.sodium,
                    servingSize: dbResult.servingSize,
                    confidence: prediction.confidencePercent,
                    brand: dbResult.brand,
                    imageURL: dbResult.imageURL
                )
                results.append(result)
            } else {
                results.append(FoodAnalysisResult(
                    name: prediction.displayName,
                    calories: 0, protein: 0, carbs: 0, fat: 0,
                    confidence: prediction.confidencePercent
                ))
            }
        }

        return results
    }

    // MARK: - Status

    var offlineAvailable: Bool {
        get async { await classifier.isAvailable }
    }

    // MARK: - Errors

    enum PipelineError: LocalizedError {
        case noOfflineModel
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .noOfflineModel: return "Offline food recognition requires the FoodClassifier model. Train it using the macOS tool."
            case .invalidImage: return "Could not process the image."
            }
        }
    }
}
