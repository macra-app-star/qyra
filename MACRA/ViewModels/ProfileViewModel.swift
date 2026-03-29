import SwiftUI
import SwiftData
import UIKit

@Observable @MainActor
final class ProfileViewModel {
    var displayName: String = ""
    var email: String = ""
    var daysTracked: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var avatarInitials: String = ""
    var profilePhoto: UIImage? = nil

    func load(container: ModelContainer) async {
        let repo = ProfileRepository(modelContainer: container)

        // Load profile photo
        if let photoData = try? await repo.fetchProfilePhoto(),
           let image = UIImage(data: photoData) {
            profilePhoto = image
        }

        if let snapshot = try? await repo.fetchProfileSnapshot() {
            displayName = snapshot.displayName ?? "User"
            // Build initials from first letter of each word (e.g. "Ben Tamras" -> "BT")
            let words = displayName.split(separator: " ").map(String.init)
            if words.count >= 2 {
                let first = String(words[0].prefix(1))
                let last = String(words[1].prefix(1))
                avatarInitials = (first + last).uppercased()
            } else if let firstWord = words.first, !firstWord.isEmpty {
                avatarInitials = String(firstWord.prefix(2)).uppercased()
            } else {
                avatarInitials = ""
            }
        }

        // Compute streak stats from MealLog data
        await loadStreakStats(container: container)
    }

    private func loadStreakStats(container: ModelContainer) async {
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<MealLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let meals = try? context.fetch(descriptor), !meals.isEmpty else { return }

        // Collect unique dates (MealLog.date is already startOfDay)
        let calendar = Calendar.current
        var uniqueDates = Set<Date>()
        for meal in meals {
            let day = calendar.startOfDay(for: meal.date)
            uniqueDates.insert(day)
        }

        let sortedDates = uniqueDates.sorted(by: >)
        daysTracked = sortedDates.count

        guard !sortedDates.isEmpty else { return }

        // Current streak: consecutive days backwards from today
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        // Allow today or yesterday as the starting point
        if sortedDates.contains(today) {
            checkDate = today
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  sortedDates.contains(yesterday) {
            checkDate = yesterday
        } else {
            currentStreak = 0
            longestStreak = computeLongestStreak(sortedDates: sortedDates, calendar: calendar)
            return
        }

        let dateSet = Set(sortedDates)
        while dateSet.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        currentStreak = streak

        // Longest streak
        longestStreak = computeLongestStreak(sortedDates: sortedDates, calendar: calendar)
    }

    private func computeLongestStreak(sortedDates: [Date], calendar: Calendar) -> Int {
        guard !sortedDates.isEmpty else { return 0 }

        // sortedDates is descending; reverse to ascending for easier processing
        let ascending = sortedDates.reversed()
        var maxStreak = 1
        var current = 1

        var previous: Date?
        for date in ascending {
            if let prev = previous {
                let diff = calendar.dateComponents([.day], from: prev, to: date).day ?? 0
                if diff == 1 {
                    current += 1
                    maxStreak = max(maxStreak, current)
                } else if diff > 1 {
                    current = 1
                }
                // diff == 0 means duplicate, skip
            }
            previous = date
        }

        return maxStreak
    }
}
