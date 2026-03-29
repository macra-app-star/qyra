import Foundation
import SwiftData

@Observable
@MainActor
final class RhythmAnalyzer {

    // MARK: - Types

    struct RhythmInsight: Identifiable {
        let id = UUID()
        let type: RhythmInsightType
        let title: String
        let body: String
        let icon: String
        let priority: Int
    }

    enum RhythmInsightType {
        case mealTiming
        case proteinPacing
        case workoutNutrition
        case weekendDrift
        case hydrationTiming
    }

    // MARK: - State

    var todayInsight: RhythmInsight?

    // MARK: - Public API

    func analyze(
        meals: [MealLog],
        exercises: [ExerciseEntry],
        water: [WaterEntry],
        days: Int = 14
    ) -> [RhythmInsight] {
        let calendar = Calendar.current
        let now = Date()
        guard let cutoff = calendar.date(byAdding: .day, value: -days, to: calendar.startOfDay(for: now)) else {
            return []
        }

        let recentMeals = meals.filter { $0.date >= cutoff }
        let recentExercises = exercises.filter { $0.timestamp >= cutoff }
        let recentWater = water.filter { $0.timestamp >= cutoff }

        var insights: [RhythmInsight] = []

        if let insight = analyzeMealTiming(meals: recentMeals, calendar: calendar) {
            insights.append(insight)
        }
        if let insight = analyzeProteinPacing(meals: recentMeals, calendar: calendar) {
            insights.append(insight)
        }
        if let insight = analyzeWorkoutNutrition(meals: recentMeals, exercises: recentExercises, calendar: calendar) {
            insights.append(insight)
        }
        if let insight = analyzeWeekendDrift(meals: recentMeals, calendar: calendar) {
            insights.append(insight)
        }
        if let insight = analyzeHydrationTiming(water: recentWater, calendar: calendar) {
            insights.append(insight)
        }

        return insights.sorted { $0.priority > $1.priority }
    }

    func pickDailyInsight(
        meals: [MealLog],
        exercises: [ExerciseEntry],
        water: [WaterEntry]
    ) {
        let insights = analyze(meals: meals, exercises: exercises, water: water)
        todayInsight = insights.first
    }

    // MARK: - 1. Meal Timing Analysis

    /// Checks if >60% of daily calories are consumed after 6 PM.
    private func analyzeMealTiming(meals: [MealLog], calendar: Calendar) -> RhythmInsight? {
        // Group meals by day
        let mealsByDay = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        guard !mealsByDay.isEmpty else { return nil }

        var daysWithLateLoading = 0
        var totalDaysWithData = 0

        for (day, dayMeals) in mealsByDay {
            let totalCals = dayMeals.reduce(0.0) { $0 + $1.totalCalories }
            guard totalCals > 0 else { continue }
            totalDaysWithData += 1

            // Calculate calories after 6 PM
            var sixPMComponents = calendar.dateComponents([.year, .month, .day], from: day)
            sixPMComponents.hour = 18
            sixPMComponents.minute = 0
            guard let sixPM = calendar.date(from: sixPMComponents) else { continue }

            let eveningCals = dayMeals.filter { meal in
                // Use the meal's actual creation time for timing (date is startOfDay)
                // Dinner and snack meals logged after 6 PM
                meal.mealType == .dinner || (meal.mealType == .snack && meal.createdAt >= sixPM)
            }.reduce(0.0) { $0 + $1.totalCalories }

            let eveningPct = eveningCals / totalCals
            if eveningPct > 0.6 {
                daysWithLateLoading += 1
            }
        }

        guard totalDaysWithData >= 7 else { return nil }

        let lateLoadPct = Double(daysWithLateLoading) / Double(totalDaysWithData)
        guard lateLoadPct > 0.5 else { return nil }

        return RhythmInsight(
            type: .mealTiming,
            title: "Evening-heavy pattern",
            body: "You tend to consume most calories after 6 PM. Shifting some intake earlier can improve energy and sleep quality.",
            icon: "moon.stars.fill",
            priority: 5
        )
    }

    // MARK: - 2. Protein Pacing Analysis

    /// Checks if >50% of daily protein comes from a single meal.
    private func analyzeProteinPacing(meals: [MealLog], calendar: Calendar) -> RhythmInsight? {
        let mealsByDay = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        guard !mealsByDay.isEmpty else { return nil }

        var daysWithPoorPacing = 0
        var totalDaysWithData = 0

        for (_, dayMeals) in mealsByDay {
            let totalProtein = dayMeals.reduce(0.0) { $0 + $1.totalProtein }
            guard totalProtein > 10 else { continue }
            totalDaysWithData += 1

            // Find the meal with the most protein
            let maxMealProtein = dayMeals.map { $0.totalProtein }.max() ?? 0
            let singleMealPct = maxMealProtein / totalProtein

            if singleMealPct > 0.5 {
                daysWithPoorPacing += 1
            }
        }

        guard totalDaysWithData >= 7 else { return nil }

        let poorPacingPct = Double(daysWithPoorPacing) / Double(totalDaysWithData)
        guard poorPacingPct > 0.5 else { return nil }

        return RhythmInsight(
            type: .proteinPacing,
            title: "Spread your protein",
            body: "Over half your daily protein is in one meal. Distributing it across meals supports better muscle synthesis.",
            icon: "chart.bar.fill",
            priority: 4
        )
    }

    // MARK: - 3. Workout Nutrition Analysis

    /// Checks if user eats within 2 hours before or after exercise.
    private func analyzeWorkoutNutrition(meals: [MealLog], exercises: [ExerciseEntry], calendar: Calendar) -> RhythmInsight? {
        guard !exercises.isEmpty else { return nil }

        var workoutsWithoutFuel = 0
        var totalWorkouts = 0

        for exercise in exercises {
            totalWorkouts += 1
            let exerciseTime = exercise.timestamp
            let twoHoursBefore = exerciseTime.addingTimeInterval(-7200)
            let twoHoursAfter = exerciseTime.addingTimeInterval(7200)

            // Check if any meal was logged on the same day within the 2-hour window
            let exerciseDay = calendar.startOfDay(for: exerciseTime)
            let sameDayMeals = meals.filter { calendar.isDate($0.date, inSameDayAs: exerciseDay) }

            let hasMealNearby = sameDayMeals.contains { meal in
                // Use createdAt as a proxy for actual eating time
                meal.createdAt >= twoHoursBefore && meal.createdAt <= twoHoursAfter
            }

            if !hasMealNearby {
                workoutsWithoutFuel += 1
            }
        }

        guard totalWorkouts >= 7 else { return nil }

        let unfueledPct = Double(workoutsWithoutFuel) / Double(totalWorkouts)
        guard unfueledPct > 0.5 else { return nil }

        return RhythmInsight(
            type: .workoutNutrition,
            title: "Fuel your workouts",
            body: "You often exercise without eating within 2 hours. A small pre or post-workout meal can boost performance and recovery.",
            icon: "bolt.heart.fill",
            priority: 3
        )
    }

    // MARK: - 4. Weekend Drift Analysis

    /// Compares average weekend calories vs weekday. Flags if difference > 300 cal.
    private func analyzeWeekendDrift(meals: [MealLog], calendar: Calendar) -> RhythmInsight? {
        let mealsByDay = Dictionary(grouping: meals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        var weekdayCalories: [Double] = []
        var weekendCalories: [Double] = []

        for (day, dayMeals) in mealsByDay {
            let totalCals = dayMeals.reduce(0.0) { $0 + $1.totalCalories }
            guard totalCals > 0 else { continue }

            let weekday = calendar.component(.weekday, from: day)
            // Sunday = 1, Saturday = 7
            if weekday == 1 || weekday == 7 {
                weekendCalories.append(totalCals)
            } else {
                weekdayCalories.append(totalCals)
            }
        }

        guard weekdayCalories.count >= 5, weekendCalories.count >= 2 else { return nil }

        let avgWeekday = weekdayCalories.reduce(0, +) / Double(weekdayCalories.count)
        let avgWeekend = weekendCalories.reduce(0, +) / Double(weekendCalories.count)
        let diff = avgWeekend - avgWeekday

        guard diff > 300 else { return nil }

        let diffRounded = Int(diff)

        return RhythmInsight(
            type: .weekendDrift,
            title: "Weekend calorie drift",
            body: "Your weekends average \(diffRounded) cal more than weekdays. Awareness can help maintain consistency.",
            icon: "calendar.badge.exclamationmark",
            priority: 2
        )
    }

    // MARK: - 5. Hydration Timing Analysis

    /// Checks if water intake is front-loaded (>60% before noon) or evenly distributed.
    private func analyzeHydrationTiming(water: [WaterEntry], calendar: Calendar) -> RhythmInsight? {
        guard water.count >= 5 else { return nil }

        // Group water entries by day
        let waterByDay = Dictionary(grouping: water) { entry in
            calendar.startOfDay(for: entry.timestamp)
        }

        var daysWithLateHydration = 0
        var totalDaysWithData = 0

        for (day, dayEntries) in waterByDay {
            let totalOz = dayEntries.reduce(0.0) { $0 + $1.amountOz }
            guard totalOz > 0 else { continue }
            totalDaysWithData += 1

            // Calculate water consumed before noon
            var noonComponents = calendar.dateComponents([.year, .month, .day], from: day)
            noonComponents.hour = 12
            noonComponents.minute = 0
            guard let noon = calendar.date(from: noonComponents) else { continue }

            let morningOz = dayEntries.filter { $0.timestamp < noon }.reduce(0.0) { $0 + $1.amountOz }
            let morningPct = morningOz / totalOz

            // Flag if less than 30% of water consumed before noon (back-loaded)
            if morningPct < 0.3 {
                daysWithLateHydration += 1
            }
        }

        guard totalDaysWithData >= 7 else { return nil }

        let lateHydrationPct = Double(daysWithLateHydration) / Double(totalDaysWithData)
        guard lateHydrationPct > 0.5 else { return nil }

        return RhythmInsight(
            type: .hydrationTiming,
            title: "Hydrate earlier",
            body: "Most of your water intake happens in the afternoon. Starting earlier helps maintain focus and energy all day.",
            icon: "drop.triangle.fill",
            priority: 1
        )
    }
}
