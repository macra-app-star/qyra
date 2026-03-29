import Foundation
import SwiftUI
import SwiftData

// MARK: - Recent Meal Item

struct RecentMealItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let calories: Int
    let time: Date
    let emoji: String
}

// MARK: - Today View Model

@Observable
@MainActor
final class TodayViewModel {

    // MARK: Page State

    var currentPage: Int = 0
    var selectedDate: Date = Date()

    // MARK: Macro Targets (from saved goal)

    var calorieTarget: Int = 2000
    var proteinTarget: Int = 150
    var carbsTarget: Int = 250
    var fatTarget: Int = 65
    var fiberTarget: Int = 30
    var sugarTarget: Int = 50
    var sodiumTarget: Int = 2300

    // MARK: Consumed Values

    var caloriesConsumed: Int = 0
    var proteinConsumed: Int = 0
    var carbsConsumed: Int = 0
    var fatConsumed: Int = 0
    var fiberConsumed: Int = 0
    var sugarConsumed: Int = 0
    var sodiumConsumed: Int = 0

    // MARK: Activity (HealthKit)

    var steps: Int = 0
    var stepsGoal: Int = 10_000
    var caloriesBurned: Int = 0

    // MARK: Water

    var waterOz: Double = 0
    var waterGoalOz: Double = 64

    // MARK: Caffeine

    var caffeineMg: Double = 0
    var caffeineGoalMg: Double = 400

    // MARK: Meta

    var weekCalories: [Date: (consumed: Int, goal: Int)] = [:]
    var dayStreak: Int = 0
    var healthScore: Double? = nil
    var isLoading: Bool = true
    var hasAnimated: Bool = false
    var errorMessage: String? = nil
    var coachInsight: String? = nil
    var isLoadingInsight: Bool = false
    private var lastInsightFetch: Date? = nil

    // MARK: Computed Remaining

    var caloriesRemaining: Int { max(0, calorieTarget - caloriesConsumed) }
    var proteinRemaining: Int { max(0, proteinTarget - proteinConsumed) }
    var carbsRemaining: Int { max(0, carbsTarget - carbsConsumed) }
    var fatRemaining: Int { max(0, fatTarget - fatConsumed) }
    var fiberRemaining: Int { max(0, fiberTarget - fiberConsumed) }
    var sugarRemaining: Int { max(0, sugarTarget - sugarConsumed) }
    var sodiumRemaining: Int { max(0, sodiumTarget - sodiumConsumed) }

    // MARK: Recent Meals

    var recentMeals: [RecentMealItem] = []
    var mealSummaries: [UUID: MealSummary] = [:]

    // MARK: Dependencies

    private var reconcileDay: ReconcileDayUseCase?
    private let healthKit = HealthKitService.shared
    var modelContainer: ModelContainer?
    private var hasRequestedHealthKit = false

    // MARK: - Init

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

    init(reconcileDay: ReconcileDayUseCase? = nil) {
        self.reconcileDay = reconcileDay
    }

    // MARK: - Public Methods

    func initialLoad() async {
        await requestHealthKitIfNeeded()
        await loadDay(selectedDate)
        await loadWeekCalories()

        try? await Task.sleep(for: .milliseconds(100))
        hasAnimated = true
    }

    func loadDay(_ date: Date) async {
        selectedDate = date
        isLoading = true
        defer { isLoading = false }

        // Load meal data via ReconcileDayUseCase
        if let reconcileDay {
            do {
                let result = try await reconcileDay.execute(for: date)
                errorMessage = nil

                // Goals
                calorieTarget = result.goal.dailyCalorieGoal
                proteinTarget = result.goal.dailyProteinGoal
                carbsTarget = result.goal.dailyCarbGoal
                fatTarget = result.goal.dailyFatGoal

                // Consumed totals
                caloriesConsumed = Int(result.summary.totalCalories)
                proteinConsumed = Int(result.summary.totalProtein)
                carbsConsumed = Int(result.summary.totalCarbs)
                fatConsumed = Int(result.summary.totalFat)
                fiberConsumed = Int(result.summary.totalFiber)
                sugarConsumed = Int(result.summary.totalSugar)
                sodiumConsumed = Int(result.summary.totalSodium)

                // Map recent meals
                let topMeals = Array(result.summary.meals.prefix(5))
                recentMeals = topMeals.map { meal in
                    RecentMealItem(
                        id: meal.id,
                        name: meal.displayDetail.isEmpty ? meal.mealType.displayName : meal.displayDetail,
                        calories: Int(meal.totalCalories),
                        time: meal.date,
                        emoji: emojiForMealType(meal.mealType)
                    )
                }
                mealSummaries = Dictionary(uniqueKeysWithValues: topMeals.map { ($0.id, $0) })
            } catch {
                errorMessage = "Unable to load today's data. Pull to refresh."
            }
        }

        // Load water entries from SwiftData
        if let container = modelContainer {
            let context = ModelContext(container)
            let startOfDay = Calendar.current.startOfDay(for: date)
            guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return }

            let waterPredicate = #Predicate<WaterEntry> { entry in
                entry.timestamp >= startOfDay && entry.timestamp < endOfDay
            }
            let waterDescriptor = FetchDescriptor<WaterEntry>(predicate: waterPredicate)
            let waterEntries = (try? context.fetch(waterDescriptor)) ?? []
            waterOz = waterEntries.reduce(0.0) { $0 + $1.amountOz }

            // Load caffeine entries
            let caffeinePredicate = #Predicate<CaffeineEntry> { entry in
                entry.timestamp >= startOfDay && entry.timestamp < endOfDay
            }
            let caffeineDescriptor = FetchDescriptor<CaffeineEntry>(predicate: caffeinePredicate)
            let caffeineEntries = (try? context.fetch(caffeineDescriptor)) ?? []
            caffeineMg = caffeineEntries.reduce(0.0) { $0 + $1.amountMg }

            // Load exercise entries
            let exercisePredicate = #Predicate<ExerciseEntry> { entry in
                entry.timestamp >= startOfDay && entry.timestamp < endOfDay
            }
            let exerciseDescriptor = FetchDescriptor<ExerciseEntry>(predicate: exercisePredicate)
            let exerciseEntries = (try? context.fetch(exerciseDescriptor)) ?? []
            caloriesBurned = Int(exerciseEntries.reduce(0.0) { $0 + $1.caloriesBurned })
        }

        // HealthKit data (additive with logged exercise)
        let hkSteps = await healthKit.steps(for: date)
        steps = hkSteps
        let hkCal = await healthKit.activeCalories(for: date)
        if hkCal > caloriesBurned { caloriesBurned = hkCal }

        // Streak calculation
        await loadStreak()

        // Health score calculation
        updateHealthScore()
    }

    private func loadStreak() async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<MealLog>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let meals = try? context.fetch(descriptor), !meals.isEmpty else {
            dayStreak = 0
            return
        }

        let calendar = Calendar.current
        var uniqueDates = Set<Date>()
        for meal in meals {
            uniqueDates.insert(calendar.startOfDay(for: meal.date))
        }

        let today = calendar.startOfDay(for: Date())
        var checkDate: Date
        if uniqueDates.contains(today) {
            checkDate = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  uniqueDates.contains(yesterday) {
            checkDate = yesterday
        } else {
            dayStreak = 0
            return
        }

        var streak = 0
        while uniqueDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        dayStreak = streak
    }

    func refresh() async {
        await loadDay(selectedDate)
        await loadWeekCalories()
    }

    func loadWeekCalories() async {
        guard let reconcileDay else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [Date: (consumed: Int, goal: Int)] = [:]
        for offset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            do {
                let reconciliation = try await reconcileDay.execute(for: date)
                result[date] = (
                    consumed: Int(reconciliation.summary.totalCalories),
                    goal: reconciliation.goal.dailyCalorieGoal
                )
            } catch {
                // Skip days that fail to load
            }
        }
        weekCalories = result
    }

    func deleteMeal(id: UUID) async {
        guard let container = modelContainer else { return }
        let repo = MealRepository(modelContainer: container)
        try? await repo.deleteMeal(id: id)
        recentMeals.removeAll { $0.id == id }
        mealSummaries.removeValue(forKey: id)
        NotificationCenter.default.post(name: .mealLogged, object: nil)
    }

    func logWater(_ oz: Double) {
        waterOz += oz

        // Persist to SwiftData
        if let container = modelContainer {
            let entry = WaterEntry(amountOz: oz)
            let context = ModelContext(container)
            context.insert(entry)
            try? context.save()
            NotificationCenter.default.post(name: .waterLogged, object: nil)
        }

        // Write to HealthKit
        Task { await HealthKitService.shared.saveWater(oz: oz, date: Date()) }
    }

    func logCaffeine(_ mg: Double) {
        caffeineMg += mg

        // Persist to SwiftData
        if let container = modelContainer {
            let entry = CaffeineEntry(amountMg: mg)
            let context = ModelContext(container)
            context.insert(entry)
            try? context.save()
            NotificationCenter.default.post(name: .caffeineLogged, object: nil)
        }
    }

    func fetchCoachInsight() async {
        guard !isLoadingInsight else { return }

        // Show local fallback immediately if no meals logged yet
        if caloriesConsumed == 0 {
            if coachInsight == nil { coachInsight = localFallbackInsight() }
            return
        }

        // Cache for 30 minutes — don't re-fetch on every view appear
        if let last = lastInsightFetch, coachInsight != nil,
           Date().timeIntervalSince(last) < 1800 {
            return
        }

        isLoadingInsight = true

        let context = """
        Daily goals: \(calorieTarget) cal, \(proteinTarget)g protein, \(carbsTarget)g carbs, \(fatTarget)g fat
        Consumed so far: \(caloriesConsumed) cal, \(proteinConsumed)g protein, \(carbsConsumed)g carbs, \(fatConsumed)g fat
        Water: \(Int(waterOz))oz / \(Int(waterGoalOz))oz
        Steps: \(steps) / \(stepsGoal)
        Exercise burned: \(caloriesBurned) cal
        Meals logged: \(recentMeals.count)
        """

        do {
            let insight = try await NutritionService.shared.getCoachInsight(context: context)
            coachInsight = insight
            lastInsightFetch = Date()
        } catch {
            coachInsight = localFallbackInsight()
        }

        isLoadingInsight = false
    }

    private func localFallbackInsight() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10:
            return "Start your morning with a protein-rich breakfast to fuel your day and keep cravings in check."
        case 10..<12:
            return "Mid-morning is a great time to hydrate. Aim for at least 8oz of water before lunch."
        case 12..<14:
            return "Lunch tip: Fill half your plate with vegetables and include a lean protein source."
        case 14..<17:
            return "Afternoon energy dip? A handful of nuts or a piece of fruit can keep you going without a sugar crash."
        case 17..<20:
            return "Planning dinner? Try to eat at least 2 hours before bed for better sleep and digestion."
        case 20..<22:
            return "Great work today! Review your macros and plan tomorrow's meals to stay on track."
        default:
            return "Consistency is key. Small daily choices add up to big results over time."
        }
    }

    // MARK: - Private

    private func requestHealthKitIfNeeded() async {
        guard !hasRequestedHealthKit, healthKit.isAvailable else { return }
        hasRequestedHealthKit = true
        _ = await healthKit.requestAuthorization()
    }

    private func updateHealthScore() {
        let mealCount = recentMeals.count
        guard mealCount > 0 else {
            healthScore = nil
            return
        }

        var score = 0.0

        // Calorie adherence (0-4)
        let calPct = calorieTarget > 0 ? Double(caloriesConsumed) / Double(calorieTarget) : 0
        if calPct >= 0.8 && calPct <= 1.1 {
            score += 4
        } else if calPct >= 0.6 && calPct <= 1.2 {
            score += 3
        } else if calPct >= 0.4 && calPct <= 1.4 {
            score += 2
        } else {
            score += 1
        }

        // Protein adherence (0-3)
        let protPct = proteinTarget > 0 ? Double(proteinConsumed) / Double(proteinTarget) : 0
        if protPct >= 0.8 {
            score += 3
        } else if protPct >= 0.5 {
            score += 2
        } else {
            score += 1
        }

        // Meal count (0-2)
        if mealCount >= 3 { score += 2 }
        else if mealCount >= 2 { score += 1 }

        // Activity bonus (0-1)
        if steps > 5000 || caloriesBurned > 200 { score += 1 }

        healthScore = min(score, 10)
    }

    private func emojiForMealType(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "🥣"
        case .lunch: return "🥗"
        case .dinner: return "🍽️"
        case .snack: return "🍎"
        }
    }
}
