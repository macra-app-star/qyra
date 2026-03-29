import Foundation
import SwiftData

@Observable
@MainActor
final class FoodSearchViewModel {
    var searchText = ""
    var results: [FoodAnalysisResult] = []
    var isSearching = false
    var errorMessage: String?
    var recentSearches: [String] = []
    var selectedMealType: MealType = .lunch
    var didSave = false

    private let mealRepository: MealRepositoryProtocol
    private let nutritionService = NutritionService.shared
    private var searchTask: Task<Void, Never>?

    convenience init(modelContainer: ModelContainer) {
        self.init(mealRepository: MealRepository(modelContainer: modelContainer))
    }

    init(mealRepository: MealRepositoryProtocol) {
        self.mealRepository = mealRepository
        loadRecentSearches()
        autoSelectMealType()
    }

    // MARK: - Search

    func onSearchTextChanged() {
        searchTask?.cancel()

        guard searchText.count >= 2 else {
            results = []
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func performSearch() async {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            let searchResults = try await nutritionService.searchFoods(query: query)
            results = searchResults
            saveRecentSearch(query)
        } catch is URLError {
            errorMessage = "Search unavailable. Check your connection and try again."
        } catch {
            errorMessage = "Search unavailable. Try again later."
        }

        isSearching = false
    }

    // MARK: - Quick Add

    func quickAdd(_ result: FoodAnalysisResult) async {
        let item = result.toNewMealItem(entryMethod: .manual)

        do {
            try await mealRepository.addMeal(
                date: Date(),
                mealType: selectedMealType,
                items: [item]
            )
            didSave = true
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }

    func selectRecentSearch(_ query: String) {
        searchText = query
        Task { await performSearch() }
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "qyra_recent_searches") ?? []
    }

    private func saveRecentSearch(_ query: String) {
        var recent = recentSearches
        recent.removeAll { $0.lowercased() == query.lowercased() }
        recent.insert(query, at: 0)
        if recent.count > 10 { recent = Array(recent.prefix(10)) }
        recentSearches = recent
        UserDefaults.standard.set(recent, forKey: "qyra_recent_searches")
    }

    func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: "qyra_recent_searches")
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
}
