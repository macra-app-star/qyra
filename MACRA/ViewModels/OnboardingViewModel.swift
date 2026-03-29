import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - Step tracking
    var currentStep: OnboardingStep = .splash
    var isComplete = false
    var showSignInSheet = false

    // MARK: - Survey fields
    var gender: Gender? = nil
    var workoutFrequency: WorkoutFrequency = .moderate
    var referralSource: ReferralSource? = nil
    var hasTriedOtherApps: Bool? = nil

    // MARK: - Height & weight (picker-based)
    var useMetric = false
    var heightFeet: Int = 5
    var heightInches: Int = 6
    var weightLbs: Int = 120
    var heightCm: Int = 168
    var weightKgPicker: Int = 54

    // MARK: - Birthday
    var birthMonth: Int = 8
    var birthDay: Int = 7
    var birthYear: Int = 2006

    // MARK: - Coach
    var hasCoach: Bool? = nil

    // MARK: - Goal fields
    var activityLevel: ActivityLevel = .moderatelyActive
    var goalType: GoalType = .maintain
    var hasSelectedGoal = false

    // MARK: - Desired weight
    var desiredWeightLbs: Double = 150
    var desiredWeightKg: Double = 68

    // MARK: - Speed
    var speedSelection: WeightSpeed = .recommended

    // MARK: - New fields (spec additions)
    var barrier: Barrier? = nil
    var dietType: DietType? = nil
    var calorieRollover: Bool? = nil
    var rating: Int = 0
    var referralCode: String = ""
    var isHealthKitAuthorized = false
    var isPlanGenerating = false

    // MARK: - Phase 2 fields
    var accomplishment: Accomplishment? = nil
    var addCaloriesBurnedBack: Bool? = nil
    var planProgress: Double = 0
    var planGenerationComplete = false

    // MARK: - Profile extras
    var firstName = ""
    var lastName = ""
    var username = ""
    var isUsernameAvailable: Bool? = nil
    var isCheckingUsername = false
    var displayName: String { "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) }

    // MARK: - Computed goals
    var calculatedCalories: Int { calculateCalories() }
    var calculatedProtein: Int { calculateProtein() }
    var calculatedCarbs: Int { calculateCarbs() }
    var calculatedFat: Int { calculateFat() }

    private let goalRepository: GoalRepositoryProtocol
    private let modelContainer: ModelContainer

    // MARK: - Derived values

    private var finalWeightKg: Double {
        if useMetric {
            return Double(weightKgPicker)
        } else {
            return Double(weightLbs) / 2.20462
        }
    }

    private var finalHeightCm: Double {
        if useMetric {
            return Double(heightCm)
        } else {
            return Double(heightFeet * 12 + heightInches) * 2.54
        }
    }

    var age: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let birthday = calendar.date(from: DateComponents(
            year: birthYear,
            month: birthMonth,
            day: birthDay
        )) else { return 25 }
        let components = calendar.dateComponents([.year], from: birthday, to: now)
        return max(1, components.year ?? 25)
    }

    // MARK: - Weight / Speed computed

    var desiredWeightDisplay: Double {
        useMetric ? desiredWeightKg : desiredWeightLbs
    }

    var weightDifferenceDisplay: Double {
        if useMetric {
            return abs(desiredWeightKg - Double(weightKgPicker))
        } else {
            return abs(desiredWeightLbs - Double(weightLbs))
        }
    }

    var weightUnit: String {
        useMetric ? "kg" : "lbs"
    }

    var goalActionVerb: String {
        switch goalType {
        case .cut: return "Losing"
        case .bulk: return "Gaining"
        case .maintain: return ""
        }
    }

    var weeklyWeightChange: Double {
        speedSelection.weeklyRate
    }

    var timelineMonths: Int {
        let diff = weightDifferenceDisplay
        guard weeklyWeightChange > 0, diff > 0 else { return 1 }
        let weeks = diff / weeklyWeightChange
        return max(1, Int(ceil(weeks / 4.33)))
    }

    var timelineLabel: String {
        if timelineMonths <= 0 { return "2 weeks" }
        if timelineMonths == 1 { return "1 month" }
        return "\(timelineMonths) months"
    }

    var speedStepTitle: String {
        switch goalType {
        case .cut: return "Weight loss speed per week"
        case .bulk: return "Weight gain speed per week"
        case .maintain: return ""
        }
    }

    var speedDescriptionForGoal: String {
        switch speedSelection {
        case .slow:
            return goalType == .cut
                ? "Going slow means a gentler and more sustainable daily calorie deficit."
                : "Going slow means a gentler and more sustainable daily calorie surplus."
        case .recommended:
            return "This is the most balanced pace, motivating and ideal for most users."
        case .fast:
            return goalType == .cut
                ? "Fast loss can lead to muscle loss or fatigue. Make sure to eat enough protein."
                : "Fast gain can lead to excess fat or bloating. Monitor your progress closely."
        }
    }

    // MARK: - Progress Bar (16 segments)

    var progressStep: Int? {
        switch currentStep {
        case .splash, .welcome, .signIn, .nameEntry, .lastNameEntry, .usernameEntry:
            return nil
        case .gender: return 1
        case .workouts: return 2
        case .attribution: return 3
        case .previousApps: return 4
        case .longTermResults: return 5
        case .heightWeight: return 6
        case .birthday: return 7
        case .coach: return 8
        case .goalSelection, .gainComparison: return 9
        case .desiredWeight, .motivation: return 10
        case .accomplishment, .weightTransition: return 11
        case .speedSelection, .barriers: return 12
        case .dietType, .caloriesBurned: return 13
        case .trust, .healthKitConnect: return 14
        case .wearableConnect: return 14
        case .calorieRollover, .allDone: return 15
        case .planGeneration, .planResults: return 16
        // Post-progress screens
        case .saveProgress, .onboardingPaywall, .trialReminder,
             .referralCode, .ratingPrompt:
            return nil
        }
    }

    var showBackButton: Bool {
        switch currentStep {
        case .splash, .welcome, .nameEntry, .lastNameEntry, .usernameEntry, .allDone, .planGeneration, .planResults,
             .saveProgress, .onboardingPaywall, .trialReminder:
            return false
        default:
            return true
        }
    }

    var showProgressBar: Bool {
        progressStep != nil
    }

    // MARK: - Init

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

    // MARK: - Goal Selection

    func selectGoal(_ type: GoalType) {
        goalType = type
        hasSelectedGoal = true

        let currentLbs = Double(weightLbs)
        let currentKg = Double(weightKgPicker)

        switch type {
        case .cut:
            desiredWeightLbs = max(60, currentLbs - 15)
            desiredWeightKg = max(30, currentKg - 7)
        case .bulk:
            desiredWeightLbs = min(400, currentLbs + 15)
            desiredWeightKg = min(200, currentKg + 7)
        case .maintain:
            desiredWeightLbs = currentLbs
            desiredWeightKg = currentKg
        }
    }

    // MARK: - Navigation

    var canContinue: Bool {
        switch currentStep {
        case .splash, .welcome, .signIn:
            return true
        case .nameEntry:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .lastNameEntry:
            return !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .usernameEntry:
            return !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isUsernameAvailable == true
        case .gender:
            return gender != nil
        case .workouts, .longTermResults, .heightWeight, .birthday,
             .desiredWeight, .motivation, .trust, .healthKitConnect,
             .wearableConnect, .gainComparison, .weightTransition, .allDone,
             .planResults, .saveProgress, .onboardingPaywall, .trialReminder:
            return true
        case .attribution:
            return referralSource != nil
        case .previousApps:
            return hasTriedOtherApps != nil
        case .coach:
            return hasCoach != nil
        case .goalSelection:
            return hasSelectedGoal
        case .speedSelection:
            return true
        case .accomplishment:
            return accomplishment != nil
        case .barriers:
            return barrier != nil
        case .dietType:
            return dietType != nil
        case .caloriesBurned:
            return addCaloriesBurnedBack != nil
        case .calorieRollover:
            return calorieRollover != nil
        case .planGeneration:
            return planGenerationComplete
        case .ratingPrompt:
            return true
        case .referralCode:
            return true
        }
    }

    func advance() {
        guard var next = currentStep.next else {
            // Final step reached — mark onboarding complete
            isComplete = true
            return
        }

        // Skip welcome carousel and sign-in — go straight to name entry
        // Auth happens later in the flow (saveProgress step)
        if next == .welcome || next == .signIn {
            next = .nameEntry
        }

        // Skip gainComparison for cut and maintain
        if next == .gainComparison && goalType != .bulk {
            next = .desiredWeight
        }

        // Skip desiredWeight/motivation for maintain (jump to accomplishment)
        if goalType == .maintain && [.desiredWeight, .motivation].contains(next) {
            next = .accomplishment
        }

        // Skip speedSelection for maintain
        if goalType == .maintain && next == .speedSelection {
            next = .barriers
        }

        // Skip referralCode — unnecessary friction
        if next == .referralCode {
            next = .ratingPrompt
        }

        currentStep = next
    }

    func goBack() {
        guard var prev = currentStep.previous else { return }

        // Skip back over speedSelection for maintain
        if goalType == .maintain && prev == .speedSelection {
            prev = .weightTransition
        }

        // Skip back over desiredWeight/motivation for maintain
        if goalType == .maintain && [.desiredWeight, .motivation].contains(prev) {
            prev = .goalSelection
        }

        // Skip back over gainComparison for cut and maintain
        if prev == .gainComparison && goalType != .bulk {
            prev = .goalSelection
        }

        currentStep = prev
    }

    func navigateTo(_ step: OnboardingStep) {
        currentStep = step
    }

    func savePlan() async {
        // Map workout frequency -> activity level
        switch workoutFrequency {
        case .low: activityLevel = .lightlyActive
        case .moderate: activityLevel = .moderatelyActive
        case .high: activityLevel = .veryActive
        }

        let goal = MacroGoalSnapshot(
            dailyCalorieGoal: calculatedCalories,
            dailyProteinGoal: calculatedProtein,
            dailyCarbGoal: calculatedCarbs,
            dailyFatGoal: calculatedFat,
            activityLevel: activityLevel,
            goalType: goalType
        )
        try? await goalRepository.saveGoal(goal)

        let profileRepo = ProfileRepository(modelContainer: modelContainer)
        // Save name + username to UserDefaults for quick access
        if !firstName.isEmpty {
            UserDefaults.standard.set(firstName, forKey: "firstName")
        }
        if !lastName.isEmpty {
            UserDefaults.standard.set(lastName, forKey: "lastName")
        }
        if !username.isEmpty {
            UserDefaults.standard.set(username.lowercased(), forKey: "username")
        }

        try? await profileRepo.saveProfile(
            displayName: displayName.isEmpty ? nil : displayName,
            weightKg: finalWeightKg,
            heightCm: finalHeightCm,
            age: age,
            gender: (gender ?? .male).rawValue
        )

        // Persist onboarding preference selections
        if let rollover = calorieRollover {
            UserDefaults.standard.set(rollover, forKey: "rolloverCalories")
        }
        if let burned = addCaloriesBurnedBack {
            UserDefaults.standard.set(burned, forKey: "addBurnedCalories")
        }

        // Persist onboarding behavioral answers (previously discarded)
        if let source = referralSource {
            UserDefaults.standard.set(source.rawValue, forKey: "onboarding_referral_source")
        }
        if let tried = hasTriedOtherApps {
            UserDefaults.standard.set(tried, forKey: "onboarding_tried_other_apps")
        }
        if let coach = hasCoach {
            UserDefaults.standard.set(coach, forKey: "onboarding_has_coach")
        }
        if let dietType = dietType {
            UserDefaults.standard.set(dietType.rawValue, forKey: "onboarding_diet_type")
        }
        if let barrier = barrier {
            UserDefaults.standard.set(barrier.rawValue, forKey: "onboarding_barrier")
        }
        if let accomplishment = accomplishment {
            UserDefaults.standard.set(accomplishment.rawValue, forKey: "onboarding_accomplishment")
        }
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: Date()), forKey: "onboarding_completed_at")

        // Analytics: onboarding completed
        AnalyticsService.shared.track(.onboardingCompleted, properties: [
            "referral_source": referralSource?.rawValue ?? "unknown",
            "goal_type": goalType.rawValue,
            "diet_type": dietType?.rawValue ?? "unknown",
            "has_coach": String(hasCoach ?? false),
            "has_tried_other_apps": String(hasTriedOtherApps ?? false)
        ])

        // Sync profile to Supabase for cross-device visibility
        if let userId = CurrentUserProvider.shared.userId {
            let uname = username.isEmpty ? "user_\(userId.prefix(8))" : username
            let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
            Task {
                try? await SupabaseAPIService.shared.upsertProfile(
                    userId: userId,
                    username: uname,
                    displayName: name.isEmpty ? uname : name
                )
            }
        }
    }

    // MARK: - Username

    func checkUsernameAvailability() async {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.count >= 3 else {
            isUsernameAvailable = nil
            return
        }

        isCheckingUsername = true

        // Check locally for reserved/invalid usernames
        let reserved = ["admin", "qyra", "support", "help", "user", "test", "null", "undefined"]
        if reserved.contains(trimmed) {
            isUsernameAvailable = false
            isCheckingUsername = false
            return
        }

        // Only alphanumeric + underscores, 3-20 chars
        let pattern = "^[a-z0-9_]{3,20}$"
        let isValid = trimmed.range(of: pattern, options: .regularExpression) != nil
        if !isValid {
            isUsernameAvailable = false
            isCheckingUsername = false
            return
        }

        // Simulate network check delay (replace with real Supabase check later)
        try? await Task.sleep(for: .milliseconds(500))
        isUsernameAvailable = true
        isCheckingUsername = false
    }

    func completeOnboarding() {
        isComplete = true
    }

    /// Legacy convenience — calls savePlan then completes
    func finish() async {
        await savePlan()
        completeOnboarding()
    }

    // MARK: - Macro Calculations (Mifflin-St Jeor)

    private func calculateTDEE() -> Double {
        let weight = finalWeightKg
        let height = finalHeightCm
        let a = Double(age)

        let bmr: Double
        if (gender ?? .male) == .female {
            bmr = 10 * weight + 6.25 * height - 5 * a - 161
        } else {
            bmr = 10 * weight + 6.25 * height - 5 * a + 5
        }

        return bmr * activityLevel.multiplier
    }

    private func calculateCalories() -> Int {
        let tdee = calculateTDEE()

        switch goalType {
        case .cut: return Int(tdee - speedSelection.dailyAdjustment)
        case .maintain: return Int(tdee)
        case .bulk: return Int(tdee + speedSelection.dailyAdjustment)
        }
    }

    private func calculateProtein() -> Int {
        let weight = finalWeightKg
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

// MARK: - Onboarding Step (33 steps)

enum OnboardingStep: Int, CaseIterable {
    case splash
    case welcome
    case signIn
    case nameEntry
    case lastNameEntry
    case usernameEntry
    case gender
    case workouts
    case attribution
    case previousApps
    case longTermResults
    case heightWeight
    case birthday
    case coach
    case goalSelection
    case gainComparison
    case desiredWeight
    case motivation
    case accomplishment
    case weightTransition
    case speedSelection
    case barriers
    case dietType
    case caloriesBurned
    case trust
    case healthKitConnect
    case wearableConnect
    case calorieRollover
    case allDone
    case planGeneration
    case planResults
    case saveProgress
    case onboardingPaywall
    case trialReminder
    case referralCode
    case ratingPrompt

    var next: OnboardingStep? {
        Self(rawValue: rawValue + 1)
    }

    var previous: OnboardingStep? {
        rawValue > 0 ? Self(rawValue: rawValue - 1) : nil
    }
}

// MARK: - Gender

enum Gender: String, CaseIterable, Identifiable {
    case male, female, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        }
    }
}

// MARK: - Workout Frequency

enum WorkoutFrequency: String, CaseIterable, Identifiable {
    case low, moderate, high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .low: return "0-2"
        case .moderate: return "3-5"
        case .high: return "6+"
        }
    }

    var subtitle: String {
        switch self {
        case .low: return "Workouts now and then"
        case .moderate: return "A few workouts per week"
        case .high: return "Dedicated athlete"
        }
    }

    var icon: String {
        switch self {
        case .low: return "circle.fill"
        case .moderate: return "dice.face.2"
        case .high: return "dice.face.6"
        }
    }
}

// MARK: - Referral Source

enum ReferralSource: String, CaseIterable, Identifiable {
    case tv, appStore, tikTok, facebook, friendOrFamily, youtube, google

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tv: return "TV"
        case .appStore: return "App Store"
        case .tikTok: return "TikTok"
        case .facebook: return "Facebook"
        case .friendOrFamily: return "Friend or family"
        case .youtube: return "Youtube"
        case .google: return "Google"
        }
    }

    var icon: String {
        switch self {
        case .tv: return "tv"
        case .appStore: return "app.badge"
        case .tikTok: return "music.note"
        case .facebook: return "person.2.fill"
        case .friendOrFamily: return "person.2"
        case .youtube: return "play.rectangle.fill"
        case .google: return "magnifyingglass"
        }
    }
}

// MARK: - Weight Speed

enum WeightSpeed: Int, CaseIterable, Identifiable {
    case slow, recommended, fast

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .slow: return "Slow"
        case .recommended: return "Recommended"
        case .fast: return "Fast"
        }
    }

    var emoji: String {
        switch self {
        case .slow: return "🐢"
        case .recommended: return "🐇"
        case .fast: return "🐆"
        }
    }

    var sfSymbol: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .recommended: return "figure.walk"
        case .fast: return "hare.fill"
        }
    }

    var weeklyRate: Double {
        switch self {
        case .slow: return 0.7
        case .recommended: return 1.6
        case .fast: return 2.5
        }
    }

    var dailyAdjustment: Double {
        switch self {
        case .slow: return 250
        case .recommended: return 500
        case .fast: return 750
        }
    }

    var speedDescription: String {
        switch self {
        case .slow:
            return "Going slow means a gentler and more sustainable daily calorie goal."
        case .recommended:
            return "This is the most balanced pace, motivating and ideal for most users."
        case .fast:
            return "Fast results but requires more discipline and higher daily intake."
        }
    }

    var etaLabel: String {
        switch self {
        case .slow: return "3 months"
        case .recommended: return "1 month"
        case .fast: return "2 weeks"
        }
    }
}

// MARK: - Barrier

enum Barrier: String, CaseIterable, Identifiable {
    case consistency, unhealthyEating, lackOfSupport, busySchedule, mealInspiration

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .consistency: return "Lack of consistency"
        case .unhealthyEating: return "Unhealthy eating habits"
        case .lackOfSupport: return "Lack of support"
        case .busySchedule: return "Busy schedule"
        case .mealInspiration: return "Lack of meal inspiration"
        }
    }

    var icon: String {
        switch self {
        case .consistency: return "chart.bar"
        case .unhealthyEating: return "fork.knife"
        case .lackOfSupport: return "bubble.left.and.bubble.right"
        case .busySchedule: return "calendar"
        case .mealInspiration: return "leaf"
        }
    }
}

// MARK: - Diet Type

enum DietType: String, CaseIterable, Identifiable {
    case classic, pescatarian, vegetarian, vegan
    case keto, paleo, mediterranean, animalBased, glutenFree, halal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .pescatarian: return "Pescatarian"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .mediterranean: return "Mediterranean"
        case .animalBased: return "Animal Based"
        case .glutenFree: return "Gluten Free"
        case .halal: return "Halal"
        }
    }

    var icon: String {
        switch self {
        case .classic: return "fork.knife"
        case .pescatarian: return "fish"
        case .vegetarian: return "leaf"
        case .vegan: return "carrot"
        case .keto: return "drop.fill"
        case .paleo: return "flame"
        case .mediterranean: return "sun.max"
        case .animalBased: return "hare"
        case .glutenFree: return "xmark.circle"
        case .halal: return "moon.stars"
        }
    }
}

// MARK: - Accomplishment

enum Accomplishment: String, CaseIterable, Identifiable {
    case eatHealthier, boostEnergy, stayMotivated, feelBetter

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eatHealthier: return "Eat and live healthier"
        case .boostEnergy: return "Boost my energy and mood"
        case .stayMotivated: return "Stay motivated and consistent"
        case .feelBetter: return "Feel better about my body"
        }
    }

    var icon: String {
        switch self {
        case .eatHealthier: return "leaf"
        case .boostEnergy: return "sun.max"
        case .stayMotivated: return "figure.mind.and.body"
        case .feelBetter: return "figure.yoga"
        }
    }
}

// MARK: - Activity Level Extension

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

// MARK: - GoalType Extension

extension GoalType {
    var onboardingLabel: String {
        switch self {
        case .cut: return "Lose weight"
        case .maintain: return "Maintain"
        case .bulk: return "Gain weight"
        }
    }

    var subtitle: String {
        switch self {
        case .cut: return "Lose fat, preserve muscle"
        case .maintain: return "Stay at current weight"
        case .bulk: return "Build muscle, gain weight"
        }
    }
}
