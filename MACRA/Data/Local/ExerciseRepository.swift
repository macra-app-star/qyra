import Foundation
import SwiftData

// INTEGRATED FROM: ExerciseDB (11,000+ exercises)
// Downloads and caches exercise data on first launch.
// Provides search by name, body part, equipment, and muscle.

@ModelActor
actor ExerciseRepository {

    // MARK: - Search

    func search(query: String, limit: Int = 30) -> [Exercise] {
        let lowered = query.lowercased()
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.searchName.contains(lowered) },
            sortBy: [SortDescriptor(\.name)]
        )
        var limited = descriptor
        limited.fetchLimit = limit
        return (try? modelContext.fetch(limited)) ?? []
    }

    func byBodyPart(_ bodyPart: String, limit: Int = 50) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.bodyPart == bodyPart },
            sortBy: [SortDescriptor(\.name)]
        )
        var limited = descriptor
        limited.fetchLimit = limit
        return (try? modelContext.fetch(limited)) ?? []
    }

    func byEquipment(_ equipment: String, limit: Int = 50) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.equipment == equipment },
            sortBy: [SortDescriptor(\.name)]
        )
        var limited = descriptor
        limited.fetchLimit = limit
        return (try? modelContext.fetch(limited)) ?? []
    }

    func byMuscle(_ muscle: String, limit: Int = 50) -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.targetMuscle == muscle },
            sortBy: [SortDescriptor(\.name)]
        )
        var limited = descriptor
        limited.fetchLimit = limit
        return (try? modelContext.fetch(limited)) ?? []
    }

    func favorites() -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func toggleFavorite(_ exerciseId: String) {
        let descriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { $0.externalId == exerciseId }
        )
        if let exercise = try? modelContext.fetch(descriptor).first {
            exercise.isFavorite.toggle()
            try? modelContext.save()
        }
    }

    // MARK: - Stats

    func totalCount() -> Int {
        let descriptor = FetchDescriptor<Exercise>()
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func isPopulated() -> Bool {
        totalCount() > 100
    }

    // MARK: - Unique Values

    func uniqueEquipment() -> [String] {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.equipment)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return Array(Set(all.map(\.equipment))).sorted()
    }

    // MARK: - Batch Import

    func batchImport(_ exercises: [Exercise]) -> Int {
        var count = 0
        for exercise in exercises {
            modelContext.insert(exercise)
            count += 1
            if count % 500 == 0 {
                try? modelContext.save()
            }
        }
        try? modelContext.save()
        return count
    }
}
