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

    struct ProfileSnapshot: Sendable {
        let displayName: String?
        let weight: Double // lbs
        let height: Double // inches
        let age: Int
        let gender: String?
        let birthDate: Date?
        let stepsTarget: Int?
        let goalWeightKg: Double?
    }

    func fetchProfileSnapshot() async throws -> ProfileSnapshot? {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        guard let profile = try modelContext.fetch(descriptor).first else { return nil }

        return ProfileSnapshot(
            displayName: profile.displayName,
            weight: (profile.weightKg ?? 0) * 2.20462,
            height: (profile.heightCm ?? 0) / 2.54,
            age: profile.age ?? 0,
            gender: profile.gender,
            birthDate: profile.birthDate,
            stepsTarget: profile.stepsTarget,
            goalWeightKg: profile.goalWeightKg
        )
    }

    func fetchDisplayName() async throws -> String? {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.displayName
    }

    func saveProfilePhoto(_ data: Data?) async throws {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let profile = try modelContext.fetch(descriptor).first {
            profile.profilePhotoData = data
            profile.updatedAt = .now
            try modelContext.save()
        }
    }

    func fetchProfilePhoto() async throws -> Data? {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.profilePhotoData
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

    /// Force-set hasCompletedOnboarding = true on the most recent profile.
    /// Creates a minimal profile if none exists.
    func markOnboardingComplete() async throws {
        var descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        if let profile = try modelContext.fetch(descriptor).first {
            profile.hasCompletedOnboarding = true
            profile.updatedAt = .now
        } else {
            // No profile exists — create a minimal one with the flag set
            let profile = UserProfile()
            profile.hasCompletedOnboarding = true
            profile.updatedAt = .now
            modelContext.insert(profile)
        }
        try modelContext.save()
    }
}
