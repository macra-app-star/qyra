import Foundation
import SwiftData

@Observable
@MainActor
final class VoiceLogViewModel {
    var transcription = ""
    var isRecording = false
    var isAnalyzing = false
    var items: [FoodAnalysisResult] = []
    var errorMessage: String?
    var selectedMealType: MealType = .lunch
    var didSave = false
    var hasPermission = false

    private let speechService = SpeechService()
    private let mealRepository: MealRepositoryProtocol
    private var listenTask: Task<Void, Never>?

    convenience init(modelContainer: ModelContainer) {
        self.init(mealRepository: MealRepository(modelContainer: modelContainer))
    }

    init(mealRepository: MealRepositoryProtocol) {
        self.mealRepository = mealRepository
        autoSelectMealType()
    }

    // MARK: - Permissions

    func checkPermission() async {
        hasPermission = await SpeechService.requestAuthorization()
    }

    // MARK: - Recording

    func startRecording() {
        guard hasPermission else { return }

        isRecording = true
        transcription = ""
        items = []
        errorMessage = nil

        listenTask = Task {
            do {
                let stream = try await speechService.startListening()
                for await text in stream {
                    transcription = text
                }
            } catch {
                errorMessage = "Recording failed: \(error.localizedDescription)"
            }

            if !Task.isCancelled && !transcription.isEmpty {
                await analyzeTranscription()
            }
            isRecording = false
        }
    }

    func stopRecording() {
        Task {
            await speechService.stopListening()
        }
        isRecording = false
    }

    // MARK: - Analysis

    private func analyzeTranscription() async {
        guard !transcription.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "No speech detected. Try again."
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            let results = try await GeminiService.shared.parseNaturalLanguage(text: transcription)
            items = results
            if items.isEmpty {
                errorMessage = "Could not identify food items. Try describing again."
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

    // MARK: - Logging

    var canLog: Bool {
        !items.isEmpty && items.allSatisfy { !$0.name.isEmpty && $0.calories > 0 }
    }

    func logMeal() async {
        guard canLog else { return }

        let newItems = items.map { $0.toNewMealItem(entryMethod: .voice) }

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

    func reset() {
        transcription = ""
        items = []
        errorMessage = nil
        isAnalyzing = false
    }

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }

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
