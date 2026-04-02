import Foundation

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayNumber: Int
    let isCurrentMonth: Bool
    let isToday: Bool
}

struct CalendarHelper {
    static func generateMonthGrid(for month: Date) -> [CalendarDay] {
        let calendar = Calendar.current

        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthRange = calendar.range(of: .day, in: .month, for: month) else {
            return []
        }

        let firstDayOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let leadingEmptyDays = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [CalendarDay] = []
        let today = calendar.startOfDay(for: Date())

        // Leading days from previous month
        if leadingEmptyDays > 0 {
            for i in stride(from: leadingEmptyDays, through: 1, by: -1) {
                if let date = calendar.date(byAdding: .day, value: -i, to: firstDayOfMonth) {
                    days.append(CalendarDay(
                        date: date,
                        dayNumber: calendar.component(.day, from: date),
                        isCurrentMonth: false,
                        isToday: false
                    ))
                }
            }
        }

        // Days of the current month
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(CalendarDay(
                    date: date,
                    dayNumber: day,
                    isCurrentMonth: true,
                    isToday: calendar.startOfDay(for: date) == today
                ))
            }
        }

        // Trailing days to fill the last row
        let remainder = days.count % 7
        if remainder > 0 {
            let trailingDays = 7 - remainder
            let lastDay = monthInterval.end
            for i in 0..<trailingDays {
                if let date = calendar.date(byAdding: .day, value: i, to: lastDay) {
                    days.append(CalendarDay(
                        date: date,
                        dayNumber: calendar.component(.day, from: date),
                        isCurrentMonth: false,
                        isToday: false
                    ))
                }
            }
        }

        return days
    }

    static func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, yyyy"
        return formatter.string(from: date)
    }
}
