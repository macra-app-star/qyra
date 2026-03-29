import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class DashboardViewModel {
    var currentCalories: Double = 0
    var currentProtein: Double = 0
    var currentCarbs: Double = 0
    var currentFat: Double = 0

    var calorieGoal: Double = 2000
    var proteinGoal: Double = 150
    var carbGoal: Double = 200
    var fatGoal: Double = 65

    var meals: [MealSummary] = []
    var isLoading = false
    var selectedDate = Date()

    var steps: Int = 0
    var activeCalories: Int = 0
    var workoutCount: Int = 0

    // Water
    var waterOunces: Int = 0
    var waterGoal: Int = 84

    // Fasting
    var fastingDisplay: String = "0:00:00"
    var fastingRemaining: String = "0:00:00"
    var fastingSchedule: String = "16:8"


    // Health Score
    var healthScore: Int = 0
    var healthScoreMessage: String = "Log meals to see your daily score"

    // AI Coach
    var coachHeadline: String = "Start logging to get insights"
    var coachMessage: String = "Log your first meal and I'll give you personalized guidance."
    var coachTip: String = ""

    // Coach tips for detail view
    var coachTips: [(icon: String, color: Color, text: String)] = []

    var displayName: String = ""
    var hasAnimated: Bool = false

    private let reconcileDay: ReconcileDayUseCase
    private let healthKit = HealthKitService.shared
    var modelContainer: ModelContainer?
    private var hasRequestedHealthKit = false

    convenience init(modelContainer: ModelContainer) {
        let mealRepo = MealRepository(modelContainer: modelContainer)
        let goalRepo = GoalRepository(modelContainer: modelContainer)
        self.init(
            reconcileDay: ReconcileDayUseCase(
                mealRepository: mealRepo,
                goalRepository: goalRepo
            )
        )
        self.modelContainer = modelContainer
    }

    init(reconcileDay: ReconcileDayUseCase) {
        self.reconcileDay = reconcileDay
    }

    func initialLoad() async {
        await loadDisplayName()
        await requestHealthKitIfNeeded()
        await loadDay()

        try? await Task.sleep(for: .milliseconds(100))
        hasAnimated = true
    }

    func loadDay() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await reconcileDay.execute(for: selectedDate)

            currentCalories = result.summary.totalCalories
            currentProtein = result.summary.totalProtein
            currentCarbs = result.summary.totalCarbs
            currentFat = result.summary.totalFat

            calorieGoal = Double(result.goal.dailyCalorieGoal)
            proteinGoal = Double(result.goal.dailyProteinGoal)
            carbGoal = Double(result.goal.dailyCarbGoal)
            fatGoal = Double(result.goal.dailyFatGoal)

            meals = result.summary.meals
        } catch {
            // Keep existing values on error
        }

        steps = await healthKit.steps(for: selectedDate)
        activeCalories = await healthKit.activeCalories(for: selectedDate)

        updateCoachInsight()
        updateHealthScore()
    }

    func refresh() async {
        await loadDay()
    }

    func deleteMeal(id: UUID) async {
        guard let container = modelContainer else { return }
        let repo = MealRepository(modelContainer: container)
        try? await repo.deleteMeal(id: id)
        DesignTokens.Haptics.medium()
        await loadDay()
    }

    // MARK: - Private

    private func loadDisplayName() async {
        guard let container = modelContainer else { return }
        let profileRepo = ProfileRepository(modelContainer: container)
        displayName = (try? await profileRepo.fetchDisplayName()) ?? ""
    }

    private func requestHealthKitIfNeeded() async {
        guard !hasRequestedHealthKit, healthKit.isAvailable else { return }
        hasRequestedHealthKit = true
        _ = await healthKit.requestAuthorization()
    }

    private func updateCoachInsight() {
        let cals = Int(currentCalories)
        let goal = Int(calorieGoal)
        _ = max(goal - cals, 0)
        let mealCount = meals.count
        let pctOfGoal = goal > 0 ? Double(cals) / Double(goal) * 100 : 0

        if mealCount == 0 {
            coachHeadline = "Start logging to get insights"
            coachMessage = "Log your first meal and I'll give you personalized guidance."
            coachTip = ""
            coachTips = []
        } else if pctOfGoal > 120 {
            coachHeadline = "Slightly over today"
            coachMessage = "You've had \(cals) calories, which is over your \(goal) goal. No worries — one day doesn't define your progress. Focus on balance tomorrow."
            coachTip = "Consider lighter options for remaining meals"
            coachTips = [
                ("lightbulb.fill", Color.orange, "Consider lighter options for remaining meals"),
                ("target", Color(red: 0.93, green: 0.32, blue: 0.32), "Balance your remaining meals with protein"),
                ("sparkles", Color.accentColor, "Consistency beats perfection every time")
            ]
        } else if pctOfGoal >= 80 {
            coachHeadline = "Great progress today"
            coachMessage = "You're right on track with \(cals) calories. Keep maintaining this balance throughout the day."
            coachTip = "Stay hydrated to support your metabolism"
            coachTips = [
                ("lightbulb.fill", Color.orange, "Log every meal for the most accurate tracking"),
                ("target", Color(red: 0.93, green: 0.32, blue: 0.32), "You're hitting your protein targets well"),
                ("sparkles", Color.accentColor, "Consistency beats perfection every time")
            ]
        } else {
            coachHeadline = "Solid progress today"
            coachMessage = "You've logged \(mealCount) meal\(mealCount == 1 ? "" : "s") with \(cals) calories so far. Keep going!"
            coachTip = "Log every meal for the most accurate tracking"
            coachTips = [
                ("lightbulb.fill", Color.orange, "Log every meal for the most accurate tracking"),
                ("target", Color(red: 0.93, green: 0.32, blue: 0.32), "Balance your remaining meals with protein"),
                ("sparkles", Color.accentColor, "Consistency beats perfection every time")
            ]
        }
    }

    private func updateHealthScore() {
        let mealCount = meals.count
        guard mealCount > 0 else {
            healthScore = 0
            healthScoreMessage = "Log meals to see your daily score"
            return
        }

        var score = 0.0

        // Calorie adherence (0-4 points)
        let calPct = calorieGoal > 0 ? currentCalories / calorieGoal : 0
        if calPct >= 0.8 && calPct <= 1.1 {
            score += 4
        } else if calPct >= 0.6 && calPct <= 1.2 {
            score += 3
        } else if calPct >= 0.4 && calPct <= 1.4 {
            score += 2
        } else {
            score += 1
        }

        // Protein adherence (0-3 points)
        let protPct = proteinGoal > 0 ? currentProtein / proteinGoal : 0
        if protPct >= 0.8 {
            score += 3
        } else if protPct >= 0.5 {
            score += 2
        } else {
            score += 1
        }

        // Meal count (0-2 points)
        if mealCount >= 3 { score += 2 }
        else if mealCount >= 2 { score += 1 }

        // Activity bonus (0-1 point)
        if steps > 5000 || activeCalories > 200 { score += 1 }

        healthScore = min(Int(score), 10)

        switch healthScore {
        case 8...10:
            healthScoreMessage = "Excellent day! You're crushing your nutrition goals."
        case 6...7:
            healthScoreMessage = "Solid progress today. Fine-tune your portions to get closer to your calorie target."
        case 4...5:
            healthScoreMessage = "Good start! Keep logging meals and staying active."
        default:
            healthScoreMessage = "Every meal logged is progress. Keep going!"
        }
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting: String
        switch hour {
        case 5..<12: timeGreeting = "Good morning"
        case 12..<17: timeGreeting = "Good afternoon"
        case 17..<22: timeGreeting = "Good evening"
        default: timeGreeting = "Good night"
        }
        if displayName.isEmpty {
            return timeGreeting
        }
        return timeGreeting
    }
}
