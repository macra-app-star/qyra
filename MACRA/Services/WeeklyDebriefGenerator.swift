import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class WeeklyDebriefGenerator {

    // MARK: - Public

    /// Generate a weekly debrief from the last 7 days of data.
    func generate(modelContainer: ModelContainer, streak: Int) -> WeeklyDebrief {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return emptyDebrief(weekStart: today, weekEnd: today)
        }

        let context = ModelContext(modelContainer)

        // Fetch meals for the week
        let startDate = weekStart
        let endDate = calendar.date(byAdding: .day, value: 1, to: today)!

        let mealPredicate = #Predicate<MealLog> { meal in
            meal.date >= startDate && meal.date < endDate
        }
        let mealDescriptor = FetchDescriptor<MealLog>(predicate: mealPredicate)
        let meals = (try? context.fetch(mealDescriptor)) ?? []

        // Fetch goal
        let goalDescriptor = FetchDescriptor<MacroGoal>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let goal = (try? context.fetch(goalDescriptor))?.first
        let calorieTarget = goal?.dailyCalorieGoal ?? 2000
        let proteinTarget = goal?.dailyProteinGoal ?? 150
        let carbTarget = goal?.dailyCarbGoal ?? 200
        let fatTarget = goal?.dailyFatGoal ?? 65

        // Guard: if no data at all, return minimal debrief
        guard !meals.isEmpty else {
            return emptyDebrief(weekStart: weekStart, weekEnd: today)
        }

        // Build per-day aggregates
        var dailyData: [Date: DayAggregate] = [:]
        for dayOffset in 0...6 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
            dailyData[day] = DayAggregate()
        }

        for meal in meals {
            let day = calendar.startOfDay(for: meal.date)
            if dailyData[day] == nil {
                dailyData[day] = DayAggregate()
            }
            dailyData[day]?.mealCount += 1
            dailyData[day]?.calories += meal.totalCalories
            dailyData[day]?.protein += meal.totalProtein
            dailyData[day]?.carbs += meal.totalCarbs
            dailyData[day]?.fat += meal.totalFat
        }

        var cards: [DebriefCard] = []

        // 1. Adherence card
        let daysTracked = dailyData.values.filter { $0.mealCount > 0 }.count
        let adherenceCard = buildAdherenceCard(daysTracked: daysTracked)
        cards.append(adherenceCard)

        // 2. Best day card
        let bestDayCard = buildBestDayCard(
            dailyData: dailyData,
            calorieTarget: calorieTarget,
            calendar: calendar
        )
        cards.append(bestDayCard)

        // 3. Pattern card
        let patternCard = buildPatternCard(
            dailyData: dailyData,
            calendar: calendar,
            weekStart: weekStart
        )
        cards.append(patternCard)

        // 4. Macro spotlight
        let macroCard = buildMacroSpotlightCard(
            dailyData: dailyData,
            proteinTarget: proteinTarget,
            carbTarget: carbTarget,
            fatTarget: fatTarget
        )
        cards.append(macroCard)

        // 5. Focus card
        let focusCard = buildFocusCard(
            dailyData: dailyData,
            daysTracked: daysTracked,
            proteinTarget: proteinTarget,
            carbTarget: carbTarget,
            fatTarget: fatTarget,
            calorieTarget: calorieTarget
        )
        cards.append(focusCard)

        // 6. Streak card
        let streakCard = buildStreakCard(streak: streak)
        cards.append(streakCard)

        return WeeklyDebrief(
            weekStartDate: weekStart,
            weekEndDate: today,
            cards: cards,
            generatedAt: Date()
        )
    }

    // MARK: - Card Builders

    private func buildAdherenceCard(daysTracked: Int) -> DebriefCard {
        let pct = Int(round(Double(daysTracked) / 7.0 * 100))
        let body: String
        if daysTracked == 7 {
            body = "You tracked every single day this week. That kind of consistency drives real results."
        } else if daysTracked >= 5 {
            body = "You logged \(daysTracked) out of 7 days. Strong week — a little more consistency and you're golden."
        } else if daysTracked >= 3 {
            body = "You tracked \(daysTracked) days this week. Building momentum — try to add one more day next week."
        } else {
            body = "You logged \(daysTracked) day\(daysTracked == 1 ? "" : "s") this week. Every entry counts — small steps lead to big change."
        }

        return DebriefCard(
            type: .adherence,
            title: "Consistency score",
            body: body,
            metric: "\(pct)%",
            trend: daysTracked >= 5 ? .up : (daysTracked >= 3 ? .flat : .down),
            accentColor: DesignTokens.Colors.accent
        )
    }

    private func buildBestDayCard(
        dailyData: [Date: DayAggregate],
        calorieTarget: Int,
        calendar: Calendar
    ) -> DebriefCard {
        let target = Double(calorieTarget)
        var bestDay: Date?
        var bestDiff: Double = .greatestFiniteMagnitude

        for (day, data) in dailyData where data.mealCount > 0 {
            let diff = abs(data.calories - target)
            if diff < bestDiff {
                bestDiff = diff
                bestDay = day
            }
        }

        let dayName: String
        if let best = bestDay {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            dayName = formatter.string(from: best)
        } else {
            dayName = "N/A"
        }

        let diffStr = bestDiff < .greatestFiniteMagnitude ? "\(Int(bestDiff))" : "—"
        let body: String
        if bestDiff < 100 {
            body = "You were only \(diffStr) calories off your target. Nailed it."
        } else if bestDiff < 300 {
            body = "Just \(diffStr) calories from your goal — that's a solid day of tracking."
        } else {
            body = "Your closest day was \(diffStr) calories from target. Progress, not perfection."
        }

        return DebriefCard(
            type: .bestDay,
            title: "Your best day",
            body: body,
            metric: dayName,
            trend: bestDiff < 200 ? .up : .flat,
            accentColor: DesignTokens.Colors.healthGreen
        )
    }

    private func buildPatternCard(
        dailyData: [Date: DayAggregate],
        calendar: Calendar,
        weekStart: Date
    ) -> DebriefCard {
        var weekdayCals: [Double] = []
        var weekendCals: [Double] = []

        for (day, data) in dailyData where data.mealCount > 0 {
            let weekday = calendar.component(.weekday, from: day)
            let isWeekend = (weekday == 1 || weekday == 7)
            if isWeekend {
                weekendCals.append(data.calories)
            } else {
                weekdayCals.append(data.calories)
            }
        }

        let avgWeekday = weekdayCals.isEmpty ? 0.0 : weekdayCals.reduce(0, +) / Double(weekdayCals.count)
        let avgWeekend = weekendCals.isEmpty ? 0.0 : weekendCals.reduce(0, +) / Double(weekendCals.count)
        let diff = abs(avgWeekday - avgWeekend)

        let title: String
        let body: String
        let trend: Trend

        if weekendCals.isEmpty || weekdayCals.isEmpty {
            title = "Pattern shift"
            body = "Not enough data yet to compare weekday vs. weekend habits. Keep logging!"
            trend = .flat
        } else if diff > 200 {
            let higher = avgWeekend > avgWeekday ? "weekends" : "weekdays"
            title = "Pattern shift"
            body = "You ate about \(Int(diff)) more calories on \(higher). Awareness is the first step to balance."
            trend = .down
        } else {
            title = "Steady pattern"
            body = "Your weekday and weekend eating stayed within \(Int(diff)) calories. Great consistency."
            trend = .up
        }

        return DebriefCard(
            type: .patternShift,
            title: title,
            body: body,
            metric: diff > 0 ? "\(Int(diff)) cal" : nil,
            trend: trend,
            accentColor: DesignTokens.Colors.aiAccent
        )
    }

    private func buildMacroSpotlightCard(
        dailyData: [Date: DayAggregate],
        proteinTarget: Int,
        carbTarget: Int,
        fatTarget: Int
    ) -> DebriefCard {
        let trackedDays = dailyData.values.filter { $0.mealCount > 0 }
        guard !trackedDays.isEmpty else {
            return DebriefCard(
                type: .macroSpotlight,
                title: "Macro spotlight",
                body: "Log more meals to see which macro you're hitting best.",
                metric: nil,
                trend: nil,
                accentColor: DesignTokens.Colors.protein
            )
        }

        let count = Double(trackedDays.count)

        // Calculate how many days each macro was within 20% of target
        var proteinHits = 0
        var carbHits = 0
        var fatHits = 0

        for day in trackedDays {
            let pPct = Double(proteinTarget) > 0 ? day.protein / Double(proteinTarget) : 0
            if pPct >= 0.8 && pPct <= 1.2 { proteinHits += 1 }

            let cPct = Double(carbTarget) > 0 ? day.carbs / Double(carbTarget) : 0
            if cPct >= 0.8 && cPct <= 1.2 { carbHits += 1 }

            let fPct = Double(fatTarget) > 0 ? day.fat / Double(fatTarget) : 0
            if fPct >= 0.8 && fPct <= 1.2 { fatHits += 1 }
        }

        let proteinPct = Int(round(Double(proteinHits) / count * 100))
        let carbPct = Int(round(Double(carbHits) / count * 100))
        let fatPct = Int(round(Double(fatHits) / count * 100))

        let bestMacro: String
        let bestPct: Int
        let accentColor: Color

        if proteinPct >= carbPct && proteinPct >= fatPct {
            bestMacro = "Protein"
            bestPct = proteinPct
            accentColor = DesignTokens.Colors.protein
        } else if carbPct >= fatPct {
            bestMacro = "Carbs"
            bestPct = carbPct
            accentColor = DesignTokens.Colors.carbs
        } else {
            bestMacro = "Fat"
            bestPct = fatPct
            accentColor = DesignTokens.Colors.fat
        }

        return DebriefCard(
            type: .macroSpotlight,
            title: "Macro spotlight",
            body: "You hit your \(bestMacro.lowercased()) target \(bestPct)% of tracked days. That's your strongest macro this week.",
            metric: bestMacro,
            trend: bestPct >= 70 ? .up : (bestPct >= 40 ? .flat : .down),
            accentColor: accentColor
        )
    }

    private func buildFocusCard(
        dailyData: [Date: DayAggregate],
        daysTracked: Int,
        proteinTarget: Int,
        carbTarget: Int,
        fatTarget: Int,
        calorieTarget: Int
    ) -> DebriefCard {
        let trackedDays = dailyData.values.filter { $0.mealCount > 0 }

        // If not enough tracking, suggest consistency
        guard trackedDays.count >= 3 else {
            return DebriefCard(
                type: .weeklyFocus,
                title: "This week's focus",
                body: "Try to log at least one meal every day. Consistency is the foundation of progress.",
                metric: nil,
                trend: nil,
                accentColor: DesignTokens.Colors.accent
            )
        }

        // Find weakest area
        let avgCal = trackedDays.map(\.calories).reduce(0, +) / Double(trackedDays.count)
        let avgProt = trackedDays.map(\.protein).reduce(0, +) / Double(trackedDays.count)

        let calDiffPct = Double(calorieTarget) > 0 ? abs(avgCal - Double(calorieTarget)) / Double(calorieTarget) : 0
        let protDiffPct = Double(proteinTarget) > 0 ? abs(avgProt - Double(proteinTarget)) / Double(proteinTarget) : 0

        let tip: String
        if daysTracked < 5 {
            tip = "Aim for 5+ tracking days. The more data you log, the better your insights become."
        } else if protDiffPct > calDiffPct && protDiffPct > 0.2 {
            if avgProt < Double(proteinTarget) {
                tip = "Protein was your weakest macro. Try adding a protein source to every meal — eggs, chicken, or Greek yogurt."
            } else {
                tip = "You went over on protein most days. Consider shifting some protein calories to carbs or fat for balance."
            }
        } else if calDiffPct > 0.15 {
            if avgCal > Double(calorieTarget) {
                tip = "You averaged \(Int(avgCal - Double(calorieTarget))) calories over target. Try pre-logging meals to stay ahead."
            } else {
                tip = "You were \(Int(Double(calorieTarget) - avgCal)) calories under target on average. Make sure you're fueling enough."
            }
        } else {
            tip = "Your nutrition was well-balanced this week. Keep it up and focus on meal timing for even better results."
        }

        return DebriefCard(
            type: .weeklyFocus,
            title: "This week's focus",
            body: tip,
            metric: nil,
            trend: nil,
            accentColor: DesignTokens.Colors.accent
        )
    }

    private func buildStreakCard(streak: Int) -> DebriefCard {
        let body: String
        if streak >= 30 {
            body = "A month-long streak. You've built a real habit — keep the momentum going."
        } else if streak >= 14 {
            body = "Two weeks strong. You're past the hardest part — this is where real change happens."
        } else if streak >= 7 {
            body = "A full week! Consistency is becoming your superpower. Don't stop now."
        } else if streak >= 3 {
            body = "You're building momentum. Three days in a row means you're forming a habit."
        } else if streak >= 1 {
            body = "Every streak starts with day one. Log tomorrow to keep it alive."
        } else {
            body = "Start fresh this week. One logged meal today begins a new streak."
        }

        return DebriefCard(
            type: .streak,
            title: "Streak update",
            body: body,
            metric: "\(streak) days",
            trend: streak >= 7 ? .up : (streak >= 3 ? .flat : .down),
            accentColor: DesignTokens.Colors.streakOrange
        )
    }

    // MARK: - Empty State

    private func emptyDebrief(weekStart: Date, weekEnd: Date) -> WeeklyDebrief {
        let adherenceCard = DebriefCard(
            type: .adherence,
            title: "Consistency score",
            body: "No meals were logged this week. Start tracking to unlock your weekly insights.",
            metric: "0%",
            trend: .down,
            accentColor: DesignTokens.Colors.accent
        )

        let focusCard = DebriefCard(
            type: .weeklyFocus,
            title: "This week's focus",
            body: "Try logging just one meal today. That single entry is the seed for everything else.",
            metric: nil,
            trend: nil,
            accentColor: DesignTokens.Colors.accent
        )

        return WeeklyDebrief(
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            cards: [adherenceCard, focusCard],
            generatedAt: Date()
        )
    }
}

// MARK: - Internal Types

private struct DayAggregate {
    var mealCount: Int = 0
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
}
