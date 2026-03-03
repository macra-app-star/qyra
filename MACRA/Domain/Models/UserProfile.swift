import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var userId: String
    var displayName: String?
    var email: String?
    var weightKg: Double?
    var heightCm: Double?
    var age: Int?
    var gender: String?
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: String = "",
        displayName: String? = nil,
        email: String? = nil,
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        age: Int? = nil,
        gender: String? = nil,
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.gender = gender
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = .now
        self.updatedAt = .now
    }
}
