import Foundation
import SwiftData

@Observable
@MainActor
final class OnboardingViewModel {
    // Step tracking
    var currentStep: OnboardingStep = .welcome
    var isComplete = false

    // Profile fields (imperial input)
    var displayName = ""
    var weightLbsText = ""
    var heightFeetText = ""
    var heightInchesText = ""
    var ageText = ""
    var gender: Gender = .preferNotToSay

    // Goal fields
    var activityLevel: ActivityLevel = .moderatelyActive
    var goalType: GoalType = .maintain

    // Computed goals
    var calculatedCalories: Int { calculateCalories() }
    var calculatedProtein: Int { calculateProtein() }
    var calculatedCarbs: Int { calculateCarbs() }
    var calculatedFat: Int { calculateFat() }

    private let goalRepository: GoalRepositoryProtocol
    private let modelContainer: ModelContainer

    // MARK: - Imperial → Metric Conversions

    private var weightKg: Double {
        let lbs = Double(weightLbsText) ?? 154
        return lbs / 2.20462
    }

    private var heightCm: Double {
        let feet = Double(heightFeetText) ?? 5
        let inches = Double(heightInchesText) ?? 9
        return (feet * 12 + inches) * 2.54
    }

    convenience init(modelContainer: ModelContainer) {
        self.init(
            goalRepository: GoalRepository(modelContainer: modelContainer),
            modelContainer: modelContainer
        )
    }

    init(goalRepository: GoalRepositoryProtocol, modelContainer: ModelContainer) {
        self.goalRepository = goalRepository
        self.modelContainer = modelContainer
    }

    func advance() {
        switch currentStep {
        case .welcome:
            currentStep = .profile
        case .profile:
            currentStep = .goals
        case .goals:
            currentStep = .review
        case .review:
            break
        }
    }

    func goBack() {
        switch currentStep {
        case .welcome:
            break
        case .profile:
            currentStep = .welcome
        case .goals:
            currentStep = .profile
        case .review:
            currentStep = .goals
        }
    }

    func finish() async {
        // Save goal
        let goal = MacroGoalSnapshot(
            dailyCalorieGoal: calculatedCalories,
            dailyProteinGoal: calculatedProtein,
            dailyCarbGoal: calculatedCarbs,
            dailyFatGoal: calculatedFat,
            activityLevel: activityLevel,
            goalType: goalType
        )
        try? await goalRepository.saveGoal(goal)

        // Save profile (convert imperial → metric for storage)
        let profileRepo = ProfileRepository(modelContainer: modelContainer)
        try? await profileRepo.saveProfile(
            displayName: displayName.isEmpty ? nil : displayName,
            weightKg: weightKg,
            heightCm: heightCm,
            age: Int(ageText),
            gender: gender.rawValue
        )

        isComplete = true
    }

    // MARK: - Macro Calculations (Mifflin-St Jeor)

    private func calculateCalories() -> Int {
        let weight = weightKg
        let height = heightCm
        let age = Double(ageText) ?? 25

        // Mifflin-St Jeor base
        let bmr: Double
        if gender == .female {
            bmr = 10 * weight + 6.25 * height - 5 * age - 161
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * age + 5
        }

        let tdee = bmr * activityLevel.multiplier

        switch goalType {
        case .cut: return Int(tdee - 500)
        case .maintain: return Int(tdee)
        case .bulk: return Int(tdee + 300)
        }
    }

    private func calculateProtein() -> Int {
        let weight = weightKg
        switch goalType {
        case .cut: return Int(weight * 2.2)
        case .maintain: return Int(weight * 1.8)
        case .bulk: return Int(weight * 2.0)
        }
    }

    private func calculateCarbs() -> Int {
        let cals = calculatedCalories
        let proteinCals = calculatedProtein * 4
        let fatCals = calculatedFat * 9
        return max(100, (cals - proteinCals - fatCals) / 4)
    }

    private func calculateFat() -> Int {
        let cals = calculatedCalories
        return Int(Double(cals) * 0.25 / 9)
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome, profile, goals, review

    var progress: Double {
        Double(rawValue + 1) / Double(Self.allCases.count)
    }
}

enum Gender: String, CaseIterable, Identifiable {
    case male, female, other, preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .preferNotToSay: return "Prefer Not to Say"
        }
    }
}

extension ActivityLevel {
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .lightlyActive: return 1.375
        case .moderatelyActive: return 1.55
        case .veryActive: return 1.725
        case .extremelyActive: return 1.9
        }
    }
}
