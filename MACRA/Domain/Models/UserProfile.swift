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

    // Phase 17 additions — nutrition targets
    var goalWeightKg: Double?
    var birthDate: Date?
    var fiberTarget: Int?
    var sugarTarget: Int?
    var sodiumTarget: Int? // mg
    var waterTargetOz: Int?
    var stepsTarget: Int?
    @Attribute(.externalStorage) var profilePhotoData: Data?

    init(
        id: UUID = UUID(),
        userId: String = "",
        displayName: String? = nil,
        email: String? = nil,
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        age: Int? = nil,
        gender: String? = nil,
        hasCompletedOnboarding: Bool = false,
        goalWeightKg: Double? = nil,
        birthDate: Date? = nil,
        fiberTarget: Int? = 30,
        sugarTarget: Int? = 50,
        sodiumTarget: Int? = 2300,
        waterTargetOz: Int? = 64,
        stepsTarget: Int? = 10000
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
        self.goalWeightKg = goalWeightKg
        self.birthDate = birthDate
        self.fiberTarget = fiberTarget
        self.sugarTarget = sugarTarget
        self.sodiumTarget = sodiumTarget
        self.waterTargetOz = waterTargetOz
        self.stepsTarget = stepsTarget
    }
}
