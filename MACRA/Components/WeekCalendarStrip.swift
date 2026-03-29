import SwiftUI

struct WeekCalendarStrip: View {
    @Binding var selectedDate: Date
    var datesWithData: Set<DateComponents> = []
    var dayStatuses: [Date: DayStatus] = [:]

    private let calendar = Calendar.current
    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return []
        }
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekInterval.start)
        }
    }

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    private func hasData(_ date: Date) -> Bool {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return datesWithData.contains(components)
    }

    private func dayNumber(_ date: Date) -> String {
        "\(calendar.component(.day, from: date))"
    }

    /// Resolve the DayStatus for a given date from the streak service data.
    private func statusForDate(_ date: Date) -> DayStatus? {
        let startOfDay = calendar.startOfDay(for: date)
        return dayStatuses[startOfDay]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekDates.enumerated()), id: \.offset) { index, date in
                Button {
                    withAnimation(DesignTokens.Anim.quick) {
                        selectedDate = date
                    }
                } label: {
                    dayColumn(date: date, letterIndex: index)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    @ViewBuilder
    private func dayColumn(date: Date, letterIndex: Int) -> some View {
        let today = isToday(date)
        let selected = isSelected(date)
        let status = statusForDate(date)

        VStack(spacing: DesignTokens.Spacing.xs) {
            // Day letter
            Text(dayLetters[letterIndex])
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(
                    today ? DesignTokens.Colors.textPrimary
                    : selected ? DesignTokens.Colors.textPrimary
                    : DesignTokens.Colors.textSecondary
                )

            // Day number with background
            ZStack {
                if today {
                    Circle()
                        .fill(DesignTokens.Colors.textPrimary)
                        .frame(width: 32, height: 32)
                } else if selected {
                    Circle()
                        .stroke(DesignTokens.Colors.textPrimary, lineWidth: 1.5)
                        .frame(width: 32, height: 32)
                }

                Text(dayNumber(date))
                    .font(DesignTokens.Typography.semibold(15))
                    .foregroundStyle(
                        today ? DesignTokens.Colors.background
                        : DesignTokens.Colors.textPrimary
                    )
            }
            .frame(width: 32, height: 32)

            // Streak indicator dot — styled by DayStatus
            streakDot(for: date, status: status)
        }
    }

    // MARK: - Streak Dot

    @ViewBuilder
    private func streakDot(for date: Date, status: DayStatus?) -> some View {
        let resolvedStatus = status ?? (hasData(date) ? .logged : nil)

        switch resolvedStatus {
        case .logged:
            // Solid filled circle — logged day
            Circle()
                .fill(DesignTokens.Colors.streakOrange)
                .frame(width: 6, height: 6)
        case .graceDay:
            // Hollow circle with dashed border — grace day (streak insurance)
            Circle()
                .stroke(
                    DesignTokens.Colors.streakOrange,
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                )
                .frame(width: 6, height: 6)
        case .missed:
            // Missed day — no dot
            Circle()
                .fill(Color.clear)
                .frame(width: 6, height: 6)
        case .future:
            // Future day — dashed outline, light gray
            Circle()
                .stroke(
                    DesignTokens.Colors.textTertiary.opacity(0.5),
                    style: StrokeStyle(lineWidth: 1, dash: [2, 2])
                )
                .frame(width: 6, height: 6)
        case nil:
            // Fallback — use original hasData logic
            Circle()
                .fill(hasData(date) ? DesignTokens.Colors.textSecondary : Color.clear)
                .frame(width: 5, height: 5)
        }
    }
}

#Preview {
    @Previewable @State var selected = Date()

    let calendar = Calendar.current
    let sampleData: Set<DateComponents> = {
        var set = Set<DateComponents>()
        for offset in [-2, -1, 0] {
            if let date = calendar.date(byAdding: .day, value: offset, to: Date()) {
                set.insert(calendar.dateComponents([.year, .month, .day], from: date))
            }
        }
        return set
    }()

    // Sample day statuses for preview
    let sampleStatuses: [Date: DayStatus] = {
        var statuses: [Date: DayStatus] = [:]
        for offset in -6...0 {
            if let date = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: Date())) {
                switch offset {
                case -6, -5, -4: statuses[date] = .logged
                case -3: statuses[date] = .graceDay
                case -2, -1: statuses[date] = .logged
                case 0: statuses[date] = .logged
                default: break
                }
            }
        }
        return statuses
    }()

    VStack {
        WeekCalendarStrip(
            selectedDate: $selected,
            datesWithData: sampleData,
            dayStatuses: sampleStatuses
        )

        Text("Selected: \(selected.formatted(date: .abbreviated, time: .omitted))")
            .font(DesignTokens.Typography.bodyFont(15))
            .foregroundStyle(DesignTokens.Colors.textSecondary)
    }
    .background(DesignTokens.Colors.background)
}
