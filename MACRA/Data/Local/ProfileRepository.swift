import Foundation
import SwiftData

@ModelActor
actor ProfileRepository {

    func saveProfile(
        displayName: String?,
        weightKg: Double?,
        heightCm: Double?,
        age: Int?,
        gender: String?
    ) async throws {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        let profile: UserProfile
        if let existing = try modelContext.fetch(descriptor).first {
            profile = existing
        } else {
            profile = UserProfile()
            modelContext.insert(profile)
        }

        profile.displayName = displayName
        profile.weightKg = weightKg
        profile.heightCm = heightCm
        profile.age = age
        profile.gender = gender
        profile.hasCompletedOnboarding = true
        profile.updatedAt = .now

        try modelContext.save()
    }

    func fetchDisplayName() async throws -> String? {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.displayName
    }

    func hasCompletedOnboarding() async throws -> Bool {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let profile = try modelContext.fetch(descriptor).first else {
            return false
        }
        return profile.hasCompletedOnboarding
    }
}
