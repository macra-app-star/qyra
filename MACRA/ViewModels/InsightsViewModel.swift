import Foundation
import SwiftData

struct DayData: Identifiable, Equatable {
    let id: Date
    let date: Date
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let calorieGoal: Double

    var adherencePercent: Double {
        guard calorieGoal > 0 else { return 0 }
        return min(calories / calorieGoal * 100, 200)
    }

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

@Observable
@MainActor
final class InsightsViewModel {
    var weekData: [DayData] = []
    var streakDays: Int = 0
    var weeklyAvgCalories: Int = 0
    var weeklyAvgProtein: Int = 0
    var isLoading = false

    private let mealRepository: MealRepositoryProtocol
    private let goalRepository: GoalRepositoryProtocol

    convenience init(modelContainer: ModelContainer) {
        self.init(
            mealRepository: MealRepository(modelContainer: modelContainer),
            goalRepository: GoalRepository(modelContainer: modelContainer)
        )
    }

    init(mealRepository: MealRepositoryProtocol, goalRepository: GoalRepositoryProtocol) {
        self.mealRepository = mealRepository
        self.goalRepository = goalRepository
    }

    func loadWeek() async {
        isLoading = true
        defer { isLoading = false }

        let goal = (try? await goalRepository.fetchCurrentGoal()) ?? .default
        let calGoal = Double(goal.dailyCalorieGoal)

        var days: [DayData] = []
        var streak = 0
        var streakBroken = false

        for offset in (0..<7).reversed() {
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) else { continue }

            let summary = (try? await mealRepository.fetchDailySummary(for: date)) ?? DailySummary(
                date: date, totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0, meals: []
            )

            let dayData = DayData(
                id: Calendar.current.startOfDay(for: date),
                date: date,
                calories: summary.totalCalories,
                protein: summary.totalProtein,
                carbs: summary.totalCarbs,
                fat: summary.totalFat,
                calorieGoal: calGoal
            )
            days.append(dayData)

            // Streak: logged at least one meal and within 120% of goal
            if !streakBroken && summary.meals.count > 0 && dayData.adherencePercent <= 120 && dayData.adherencePercent >= 50 {
                streak += 1
            } else if summary.meals.count > 0 {
                streakBroken = true
            }
        }

        weekData = days

        let daysWithData = days.filter { $0.calories > 0 }
        if !daysWithData.isEmpty {
            weeklyAvgCalories = Int(daysWithData.reduce(0) { $0 + $1.calories } / Double(daysWithData.count))
            weeklyAvgProtein = Int(daysWithData.reduce(0) { $0 + $1.protein } / Double(daysWithData.count))
        }
        streakDays = streak
    }
}
