import Foundation
import SwiftUI
import SwiftData

@Observable
@MainActor
final class ProgressViewModel {

    // MARK: - Weight

    var currentWeight: Double? = nil
    var startWeight: Double? = nil
    var goalWeight: Double? = nil
    var goalDate: Date? = nil
    var heightInches: Double? = nil
    var weightEntries: [WeightEntry] = []

    // MARK: - Streak & Badges

    var dayStreak: Int = 0
    var badgesEarned: Int = 0

    // MARK: - Filters

    var weightChartFilter: String = "90D"
    var energyWeekFilter: String = "This wk"
    var caloriesWeekFilter: String = "This wk"

    // MARK: - Weekly Energy Data

    var weeklyEnergyData: [(label: String, value: Double)] = []
    var weeklyBurned: Double = 0
    var weeklyConsumed: Double = 0
    var weeklyNetEnergy: Double = 0

    // MARK: - Weight Changes

    struct WeightChange: Identifiable {
        let id = UUID()
        let period: String
        let change: Double?
        let isPositive: Bool?
    }

    var weightChanges: [WeightChange] = []

    // MARK: - Expenditure Changes

    struct ExpenditureChange: Identifiable {
        let id = UUID()
        let period: String
        let change: Double?
        let isPositive: Bool?
    }

    var expenditureChanges: [ExpenditureChange] = []

    // MARK: - Loading

    var isLoading = true

    // MARK: - Dependencies

    private var modelContainer: ModelContainer?
    private let mealRepository: MealRepositoryProtocol?
    private let healthKit = HealthKitService.shared

    // MARK: - Init

    convenience init(modelContainer: ModelContainer) {
        self.init(
            modelContainer: modelContainer,
            mealRepository: MealRepository(modelContainer: modelContainer)
        )
    }

    init(modelContainer: ModelContainer? = nil, mealRepository: MealRepositoryProtocol? = nil) {
        self.modelContainer = modelContainer
        self.mealRepository = mealRepository
    }

    // MARK: - Computed Properties

    var weightProgress: Double {
        guard let start = startWeight,
              let goal = goalWeight,
              let current = currentWeight else { return 0 }
        let totalDelta = abs(goal - start)
        guard totalDelta > 0 else { return 0 }
        let progressDelta = abs(current - start)
        return min(max(progressDelta / totalDelta, 0), 1)
    }

    var bmi: Double? {
        guard let weight = currentWeight,
              let height = heightInches,
              height > 0 else { return nil }
        return (weight * 703) / (height * height)
    }

    var bmiCategory: String {
        guard let bmi else { return "Unknown" }
        switch bmi {
        case ..<18.5: return "Underweight"
        case 18.5..<25: return "Normal"
        case 25..<30: return "Overweight"
        default: return "Obese"
        }
    }

    var formattedCurrentWeight: String {
        guard let w = currentWeight else { return "\u{2014} lbs" }
        return String(format: "%.1f lbs", w)
    }

    var formattedStartWeight: String {
        guard let w = startWeight else { return "\u{2014}" }
        return String(format: "%.0f", w)
    }

    var formattedGoalWeight: String {
        guard let w = goalWeight else { return "\u{2014}" }
        return String(format: "%.0f", w)
    }

    var formattedGoalDate: String? {
        guard let date = goalDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    var formattedBMI: String {
        guard let bmi else { return "\u{2014}" }
        return String(format: "%.1f", bmi)
    }

    // MARK: - Lifecycle

    func initialLoad() async {
        isLoading = true
        defer { isLoading = false }

        await loadUserProfile()
        await loadWeightData()
        await loadWeeklyEnergy()
        await loadStreak()
    }

    // MARK: - User Profile

    private func loadUserProfile() async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<UserProfile>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        guard let profile = try? context.fetch(descriptor).first else { return }

        if let heightCm = profile.heightCm, heightCm > 0 {
            heightInches = heightCm / 2.54
        }

        if let goalKg = profile.goalWeightKg {
            goalWeight = goalKg * 2.20462
        }
    }

    // MARK: - Weight Data

    private func loadWeightData() async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        // Fetch all weight entries sorted by date
        let descriptor = FetchDescriptor<WeightEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        weightEntries = entries

        if let first = entries.first {
            startWeight = first.weightLbs
        }
        if let last = entries.last {
            currentWeight = last.weightLbs
        }

        // Weight changes for different periods
        let periods: [(String, Int)] = [("3d", 3), ("7d", 7), ("14d", 14), ("30d", 30), ("90d", 90)]
        weightChanges = periods.map { (label, days) in
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let oldEntry = entries.last(where: { $0.timestamp <= cutoff })
            let change: Double?
            let isPositive: Bool?
            if let old = oldEntry, let current = entries.last {
                let delta = current.weightLbs - old.weightLbs
                change = delta
                isPositive = delta > 0
            } else {
                change = nil
                isPositive = nil
            }
            return WeightChange(period: label, change: change, isPositive: isPositive)
        }
        // Add "All" period
        if let first = entries.first, let last = entries.last, entries.count > 1 {
            let delta = last.weightLbs - first.weightLbs
            weightChanges.append(WeightChange(period: "All", change: delta, isPositive: delta > 0))
        } else {
            weightChanges.append(WeightChange(period: "All", change: nil, isPositive: nil))
        }
    }

    // MARK: - Weekly Energy

    private func loadWeeklyEnergy() async {
        guard let mealRepository else {
            weeklyEnergyData = dayLabelsForWeek().map { (label: $0, value: 0.0) }
            return
        }

        let calendar = Calendar.current
        var data: [(label: String, value: Double)] = []
        var totalConsumed: Double = 0
        var totalBurned: Double = 0

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        for offset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { continue }

            let summary = (try? await mealRepository.fetchDailySummary(for: date)) ?? DailySummary(
                date: date, totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0,
                totalFiber: 0, totalSugar: 0, totalSodium: 0, meals: []
            )

            let consumed = summary.totalCalories
            totalConsumed += consumed

            let burned = Double(await healthKit.activeCalories(for: date))
            totalBurned += burned

            let net = consumed - burned
            data.append((label: formatter.string(from: date), value: net))
        }

        weeklyEnergyData = data
        weeklyConsumed = totalConsumed
        weeklyBurned = totalBurned
        weeklyNetEnergy = totalConsumed - totalBurned

        // Expenditure changes
        let periods: [(String, Int)] = [("3d", 3), ("7d", 7), ("14d", 14), ("30d", 30), ("90d", 90)]
        expenditureChanges = periods.map { ExpenditureChange(period: $0.0, change: nil, isPositive: nil) }
        expenditureChanges.append(ExpenditureChange(period: "All", change: nil, isPositive: nil))
    }

    // MARK: - Streak

    private func loadStreak() async {
        guard let container = modelContainer else { return }
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<MealLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let meals = try? context.fetch(descriptor), !meals.isEmpty else {
            dayStreak = 0
            badgesEarned = 0
            return
        }

        // Collect unique dates (same logic as ProfileViewModel)
        let calendar = Calendar.current
        var uniqueDates = Set<Date>()
        for meal in meals {
            let day = calendar.startOfDay(for: meal.date)
            uniqueDates.insert(day)
        }

        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        // Allow today or yesterday as the starting point
        if uniqueDates.contains(today) {
            checkDate = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  uniqueDates.contains(yesterday) {
            checkDate = yesterday
        } else {
            dayStreak = 0
            badgesEarned = 0
            return
        }

        while uniqueDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        dayStreak = streak
        badgesEarned = streak / 7 // 1 badge per 7 consecutive days
    }

    // MARK: - Helpers

    private func dayLabelsForWeek() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).reversed().compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return formatter.string(from: date)
        }
    }
}
