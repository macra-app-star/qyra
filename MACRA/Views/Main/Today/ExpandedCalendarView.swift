import SwiftUI

struct ExpandedCalendarView: View {
    var viewModel: TodayViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    private let weekdaySymbols: [String] = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.veryShortWeekdaySymbols
    }()

    var body: some View {
        VStack(spacing: 12) {
            // Month header with navigation
            monthHeader

            // Weekday labels
            weekdayLabels

            // Calendar grid
            calendarGrid

            // Streak card
            StreakCardView(
                currentStreak: viewModel.dayStreak,
                longestStreak: viewModel.longestStreak
            )
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button {
                viewModel.navigateMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(CalendarHelper.monthYearString(from: viewModel.calendarDisplayMonth))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(.label))

            Spacer()

            Button {
                viewModel.navigateMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(.label))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Weekday Labels

    private var weekdayLabels: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(reorderedWeekdays(), id: \.self) { symbol in
                Text(symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        let days = CalendarHelper.generateMonthGrid(for: viewModel.calendarDisplayMonth)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days) { day in
                CalendarDayCell(
                    day: day,
                    status: viewModel.calendarDayStatuses[Calendar.current.startOfDay(for: day.date)],
                    isSelected: Calendar.current.isDate(day.date, inSameDayAs: viewModel.selectedDate),
                    onTap: {
                        if day.isCurrentMonth {
                            viewModel.selectDate(day.date)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .id(viewModel.calendarDisplayMonth)
        .transition(.opacity)
    }

    // MARK: - Helpers

    private func reorderedWeekdays() -> [String] {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday - 1 // 0-indexed
        var symbols = weekdaySymbols
        let prefix = symbols.prefix(firstWeekday)
        symbols.removeFirst(firstWeekday)
        symbols.append(contentsOf: prefix)
        return symbols
    }
}
