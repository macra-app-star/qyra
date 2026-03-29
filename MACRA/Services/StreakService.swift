import Foundation
import SwiftData

// MARK: - Streak Types

struct StreakResult {
    let currentStreak: Int
    let longestStreak: Int
    let graceDaysUsedThisWeek: Int
    let graceDaysAvailable: Int
    let dayStatuses: [Date: DayStatus]
}

enum DayStatus {
    case logged
    case graceDay
    case missed
    case future
}

// MARK: - Streak Service

@Observable
@MainActor
final class StreakService {

    var currentResult: StreakResult?

    private let calendar = Calendar.current

    func calculateStreak(meals: [MealLog]) -> StreakResult {
        let today = calendar.startOfDay(for: Date())

        // Build a set of days that have at least 1 meal logged
        var loggedDays = Set<Date>()
        for meal in meals {
            let day = calendar.startOfDay(for: meal.date)
            loggedDays.insert(day)
        }

        // Walk backwards from today to find current streak (with grace days)
        var currentStreak = 0
        var longestStreak = 0
        var runningStreak = 0
        var graceDaysUsedThisWeek = 0
        var dayStatuses: [Date: DayStatus] = [:]

        // First pass: calculate the raw streak walking backward from today
        // We need to look back far enough to find the longest streak
        let lookbackDays = 365
        var streakBroken = false
        var consecutiveGraceDays = 0

        for dayOffset in 0..<lookbackDays {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }

            if day > today {
                // Future day
                continue
            }

            let isLogged = loggedDays.contains(day)

            if isLogged {
                runningStreak += 1
                consecutiveGraceDays = 0

                if !streakBroken {
                    currentStreak = runningStreak
                }
            } else if !streakBroken {
                // Check if this day qualifies as a grace day
                let graceDaysAllowed = graceDaysAllowedForStreak(runningStreak)
                let weekGraceUsed = countGraceDaysInSameWeek(as: day, in: dayStatuses)

                if graceDaysAllowed > 0 && weekGraceUsed < graceDaysAllowed && consecutiveGraceDays < 1 {
                    // This is a grace day - streak continues
                    runningStreak += 1
                    consecutiveGraceDays += 1
                    currentStreak = runningStreak
                    dayStatuses[day] = .graceDay

                    // Count grace days used this week (for today's week)
                    if isInCurrentWeek(day) {
                        graceDaysUsedThisWeek += 1
                    }
                    continue
                } else {
                    // Streak broken
                    streakBroken = true
                    longestStreak = max(longestStreak, runningStreak)
                    runningStreak = 0
                    consecutiveGraceDays = 0
                }
            } else {
                // Already past a break, looking for longest
                // Note: isLogged days are handled by the first branch above
                longestStreak = max(longestStreak, runningStreak)
                runningStreak = 0
            }
        }
        longestStreak = max(longestStreak, runningStreak)
        longestStreak = max(longestStreak, currentStreak)

        // Second pass: build dayStatuses for the last 7 days
        dayStatuses = [:] // Reset and rebuild for display
        graceDaysUsedThisWeek = 0

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            if day > today {
                dayStatuses[day] = .future
                continue
            }

            let isLogged = loggedDays.contains(day)

            if isLogged {
                dayStatuses[day] = .logged
            } else if dayOffset == 0 {
                // Today and not yet logged - show as current (not missed yet)
                dayStatuses[day] = .missed
            } else {
                // Check if this would have been a grace day
                let graceDaysAllowed = graceDaysAllowedForStreak(currentStreak)
                let weekGraceUsed = countGraceDaysInSameWeek(as: day, in: dayStatuses)

                if graceDaysAllowed > 0 && weekGraceUsed < graceDaysAllowed {
                    dayStatuses[day] = .graceDay
                    if isInCurrentWeek(day) {
                        graceDaysUsedThisWeek += 1
                    }
                } else {
                    dayStatuses[day] = .missed
                }
            }
        }

        // Also populate future days in the current week
        for dayOffset in 1...6 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            let weekOfToday = calendar.component(.weekOfYear, from: today)
            let weekOfDay = calendar.component(.weekOfYear, from: day)
            if weekOfToday == weekOfDay {
                dayStatuses[day] = .future
            }
        }

        let graceDaysAvailable = graceDaysAllowedForStreak(currentStreak)

        let result = StreakResult(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            graceDaysUsedThisWeek: graceDaysUsedThisWeek,
            graceDaysAvailable: graceDaysAvailable,
            dayStatuses: dayStatuses
        )

        currentResult = result
        return result
    }

    // MARK: - Helpers

    /// Grace days allowed: 1 if streak >= 7, 2 if streak >= 30
    private func graceDaysAllowedForStreak(_ streak: Int) -> Int {
        if streak >= 30 { return 2 }
        if streak >= 7 { return 1 }
        return 0
    }

    /// Count how many grace days are already in the same ISO week as the given date.
    private func countGraceDaysInSameWeek(as date: Date, in statuses: [Date: DayStatus]) -> Int {
        let targetWeek = calendar.component(.weekOfYear, from: date)
        let targetYear = calendar.component(.yearForWeekOfYear, from: date)

        return statuses.filter { (day, status) in
            guard status == .graceDay else { return false }
            let week = calendar.component(.weekOfYear, from: day)
            let year = calendar.component(.yearForWeekOfYear, from: day)
            return week == targetWeek && year == targetYear
        }.count
    }

    /// Checks if a date falls within the current calendar week.
    private func isInCurrentWeek(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
    }
}
