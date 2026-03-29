import Foundation
import SwiftData

/// Unified facade for all food-related API operations.
/// Wraps USDA, OpenFoodFacts, and Gemini services into a single interface.
/// Caches API results locally via FoodProductRepository for offline use.
@MainActor
final class NutritionService: ObservableObject {
    static let shared = NutritionService()

    @Published var isLoading = false

    private let usdaService = USDAService.shared
    private let openFoodFactsService = OpenFoodFactsService.shared
    private let geminiService = GeminiService.shared

    // FoodProduct cache — set after ModelContainer is available
    private var _modelContainer: ModelContainer?

    /// Call once after ModelContainer is ready (e.g., from AppState)
    func configure(modelContainer: ModelContainer) {
        self._modelContainer = modelContainer
    }

    private func makeFoodRepo() -> FoodProductRepository? {
        guard let container = _modelContainer else { return nil }
        return FoodProductRepository(modelContainer: container)
    }

    // MARK: - Search Foods

    /// Search foods by text query — local cache first, then APIs
    func searchFoods(query: String) async throws -> [FoodAnalysisResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        // 1. Check local cache first
        var results: [FoodAnalysisResult] = []
        if let repo = makeFoodRepo() {
            let cached = await repo.search(query: trimmed, limit: 10)
            results.append(contentsOf: cached.map { $0.toFoodAnalysisResult() })
        }

        // 2. Fan out to USDA API
        do {
            let usda = try await usdaService.search(query: trimmed, pageSize: 25)
            let apiResults = usda.map { $0.toFoodAnalysisResult() }
            results.append(contentsOf: apiResults)
        } catch {
            // If API fails and we have cache results, continue with those
            if results.isEmpty { throw error }
        }

        // Deduplicate by name (prefer higher confidence)
        let deduped = Dictionary(grouping: results) { $0.name.lowercased() }
            .compactMap { $0.value.max(by: { $0.confidence < $1.confidence }) }

        // Sort by relevance
        return deduped.sorted { a, b in
            let aExact = a.name.lowercased().contains(trimmed.lowercased())
            let bExact = b.name.lowercased().contains(trimmed.lowercased())
            if aExact != bExact { return aExact }
            return a.confidence > b.confidence
        }
    }

    // MARK: - Barcode Lookup

    /// Look up food by barcode — local cache first, then OpenFoodFacts API
    func lookupBarcode(_ barcode: String) async throws -> FoodAnalysisResult? {
        // 1. Check local cache
        if let repo = makeFoodRepo(),
           let cached = await repo.findByBarcode(barcode) {
            return cached.toFoodAnalysisResult()
        }

        // 2. Try OpenFoodFacts API
        if let result = try? await openFoodFactsService.lookupBarcode(barcode) {
            // Cache for offline use
            await cacheBarcodeLookup(barcode: barcode, result: result, source: "openfoodfacts")
            return result
        }

        return nil
    }

    // MARK: - AI Food Recognition

    /// AI-powered food recognition from image
    func recognizeFood(imageData: Data) async throws -> [FoodAnalysisResult] {
        try await geminiService.analyzeFoodPhoto(imageData: imageData)
    }

    // MARK: - Voice Food Parsing

    /// AI-powered food logging from voice transcript
    func parseVoiceLog(transcript: String) async throws -> [FoodAnalysisResult] {
        try await geminiService.parseNaturalLanguage(text: transcript)
    }

    // MARK: - AI Coach

    /// Get AI coaching insight based on daily context
    func getCoachInsight(context: String) async throws -> String {
        let systemPrompt = """
        You are Qyra AI, a concise nutrition coach. \
        Given the user's daily intake and goals, provide a brief insight \
        (2-3 sentences max). Be specific about what they should eat next. \
        Never give medical advice.
        """
        return try await geminiService.chat(
            userMessage: context,
            systemContext: systemPrompt
        )
    }

    // MARK: - Exercise Estimation

    /// Estimate calories burned from exercise description
    func estimateExercise(
        description: String,
        weightKg: Double,
        durationMinutes: Int
    ) async throws -> ExerciseEstimate {
        let prompt = """
        User weighs \(Int(weightKg)) kg and exercised for \(durationMinutes) minutes.
        Exercise: \(description)

        Return ONLY a JSON object with these fields:
        { "exercise_name": string, "duration_minutes": number, "calories_burned": number, "met_value": number }

        Use standard MET calculations. Be conservative with estimates.
        """

        let systemContext = "You are a fitness expert. Estimate calories burned accurately using MET values."
        let response = try await geminiService.chat(
            userMessage: prompt,
            systemContext: systemContext
        )

        guard response.data(using: .utf8) != nil else {
            throw APIError.noData
        }

        let jsonString = extractJSON(from: response)
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw APIError.noData
        }

        return try JSONDecoder().decode(ExerciseEstimate.self, from: jsonData)
    }

    // MARK: - Cache Stats

    /// Get total count of locally cached food products
    func cachedProductCount() async -> Int {
        guard let repo = makeFoodRepo() else { return 0 }
        return await repo.totalCount()
    }

    // MARK: - Private Helpers

    private func cacheBarcodeLookup(barcode: String, result: FoodAnalysisResult, source: String) async {
        guard let repo = makeFoodRepo() else { return }

        let product = FoodProduct(
            barcode: barcode,
            name: result.name,
            brands: result.brand,
            caloriesPer100g: result.calories,
            proteinPer100g: result.protein,
            carbsPer100g: result.carbs,
            fatPer100g: result.fat,
            fiberPer100g: result.fiber,
            sugarPer100g: result.sugar,
            sodiumPer100g: result.sodium,
            servingSize: result.servingSize,
            source: source
        )
        await repo.upsert(product)
    }

    private func extractJSON(from text: String) -> String {
        var cleaned = text
        if cleaned.contains("```json") {
            cleaned = cleaned
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
        } else if cleaned.contains("```") {
            cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Exercise Estimate DTO

struct ExerciseEstimate: Codable, Sendable {
    let exerciseName: String
    let durationMinutes: Int
    let caloriesBurned: Double
    let metValue: Double

    enum CodingKeys: String, CodingKey {
        case exerciseName = "exercise_name"
        case durationMinutes = "duration_minutes"
        case caloriesBurned = "calories_burned"
        case metValue = "met_value"
    }
}
