import Foundation
import SwiftData

// INTEGRATED FROM: Free Exercise DB (800+) + ExerciseDB mirrors (1300+)
// Downloads exercise JSON data on first launch and imports into SwiftData.
// Supports expanding with additional sources via user-triggered download.

@MainActor
final class ExerciseImportService: ObservableObject {
    static let shared = ExerciseImportService()

    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importedCount: Int = 0
    @Published var errorMessage: String?

    // Primary: free-exercise-db — public domain, 800+ exercises
    private let freeExerciseDBURL = "https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json"

    // Expansion: ExerciseDB API mirror — 1300+ exercises with GIF URLs
    private let exerciseDBExpandedURL = "https://raw.githubusercontent.com/bryanprimus/exercisedb-api/main/exercises.json"

    private var modelContainer: ModelContainer?

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Check if exercise database needs population, and import if empty
    func importIfNeeded() async {
        guard let container = modelContainer else { return }
        let repo = ExerciseRepository(modelContainer: container)
        let populated = await repo.isPopulated()
        if !populated {
            await importFreeExerciseDB()
        }
    }

    // MARK: - Primary Import (auto, first launch)

    /// Download and import exercises from free-exercise-db (800+)
    func importFreeExerciseDB() async {
        await importFrom(
            url: freeExerciseDBURL,
            source: "free-exercise-db",
            parser: parseFreeExerciseDB
        )
    }

    // MARK: - Expanded Import (user-triggered)

    /// Download and merge additional exercises from ExerciseDB mirror (1300+)
    func importExpandedExerciseDB() async {
        await importFrom(
            url: exerciseDBExpandedURL,
            source: "exercisedb",
            parser: parseExerciseDBExpanded
        )
    }

    /// Total exercises across all sources
    func totalExerciseCount() async -> Int {
        guard let container = modelContainer else { return 0 }
        let repo = ExerciseRepository(modelContainer: container)
        return await repo.totalCount()
    }

    // MARK: - Generic Import

    private func importFrom(
        url urlString: String,
        source: String,
        parser: @escaping (Data) throws -> [Exercise]
    ) async {
        guard let container = modelContainer else { return }
        guard !isImporting else { return }

        isImporting = true
        importProgress = 0
        errorMessage = nil

        do {
            importProgress = 0.1
            guard let url = URL(string: urlString) else {
                throw URLError(.badURL)
            }

            let (data, _) = try await URLSession.shared.data(from: url)
            importProgress = 0.4

            let exercises = try parser(data)
            importProgress = 0.6

            let repo = ExerciseRepository(modelContainer: container)
            let count = await repo.batchImport(exercises)
            importedCount += count
            importProgress = 1.0

        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
        }

        isImporting = false
    }

    // MARK: - Parsers

    private func parseFreeExerciseDB(_ data: Data) throws -> [Exercise] {
        let raw = try JSONDecoder().decode([FreeExerciseDTO].self, from: data)
        return raw.enumerated().map { index, dto in
            Exercise(
                externalId: dto.id ?? "free-\(index)",
                name: dto.name,
                bodyPart: dto.primaryMuscles?.first?.lowercased() ?? dto.category?.lowercased() ?? "",
                targetMuscle: dto.primaryMuscles?.first?.lowercased() ?? "",
                secondaryMuscles: dto.secondaryMuscles ?? [],
                equipment: dto.equipment?.lowercased() ?? "body only",
                instructions: dto.instructions ?? [],
                gifURL: dto.images?.first,
                metValue: metValueForCategory(dto.category),
                source: "free-exercise-db"
            )
        }
    }

    private func parseExerciseDBExpanded(_ data: Data) throws -> [Exercise] {
        let raw = try JSONDecoder().decode([ExerciseDBDTO].self, from: data)
        return raw.map { dto in
            Exercise(
                externalId: dto.id ?? UUID().uuidString,
                name: dto.name,
                bodyPart: dto.bodyPart?.lowercased() ?? "",
                targetMuscle: dto.target?.lowercased() ?? "",
                secondaryMuscles: dto.secondaryMuscles ?? [],
                equipment: dto.equipment?.lowercased() ?? "body weight",
                instructions: dto.instructions ?? [],
                gifURL: dto.gifUrl,
                metValue: metValueForBodyPart(dto.bodyPart),
                source: "exercisedb"
            )
        }
    }

    // MARK: - MET Estimation

    private func metValueForCategory(_ category: String?) -> Double {
        switch category?.lowercased() {
        case "cardio": return 8.0
        case "olympic weightlifting": return 6.0
        case "plyometrics": return 8.0
        case "powerlifting": return 6.0
        case "strength": return 5.0
        case "stretching": return 2.5
        case "strongman": return 7.0
        default: return 5.0
        }
    }

    private func metValueForBodyPart(_ bodyPart: String?) -> Double {
        switch bodyPart?.lowercased() {
        case "cardio": return 8.0
        case "waist": return 4.0
        case "upper legs", "lower legs": return 6.0
        case "back", "chest": return 5.5
        case "shoulders", "upper arms", "lower arms": return 5.0
        case "neck": return 3.0
        default: return 5.0
        }
    }
}

// MARK: - DTOs

private struct FreeExerciseDTO: Codable {
    let id: String?
    let name: String
    let category: String?
    let primaryMuscles: [String]?
    let secondaryMuscles: [String]?
    let equipment: String?
    let instructions: [String]?
    let images: [String]?
    let level: String?
    let force: String?
    let mechanic: String?
}

private struct ExerciseDBDTO: Codable {
    let id: String?
    let name: String
    let bodyPart: String?
    let target: String?
    let secondaryMuscles: [String]?
    let equipment: String?
    let instructions: [String]?
    let gifUrl: String?
}
