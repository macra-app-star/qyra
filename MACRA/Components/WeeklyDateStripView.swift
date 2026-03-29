import SwiftUI

struct WeeklyDateStripView: View {
    @Binding var selectedDate: Date
    var dayCalories: [Date: (consumed: Int, goal: Int)] = [:]
    private let calendar = Calendar.current

    private var weekDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        return (-6...0).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: today)
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                dateCell(date)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func dateCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(dayOfWeek(date))
                    .font(QyraFont.regular(11))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                ZStack {
                    if isSelected || isToday {
                        // Today and selected: solid black filled circle
                        Circle()
                            .fill(DesignTokens.Colors.textPrimary)
                            .frame(width: 36, height: 36)
                    } else if let adherenceColor = adherenceColor(for: date) {
                        Circle()
                            .strokeBorder(adherenceColor, lineWidth: 2)
                            .frame(width: 36, height: 36)
                    } else {
                        Circle()
                            .strokeBorder(DesignTokens.Colors.border, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                            .frame(width: 36, height: 36)
                    }

                    Text(dayNumber(date))
                        .font((isSelected || isToday) ? QyraFont.bold(14) : QyraFont.regular(14))
                        .foregroundStyle((isSelected || isToday) ? DesignTokens.Colors.background : DesignTokens.Colors.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func adherenceColor(for date: Date) -> Color? {
        let key = calendar.startOfDay(for: date)
        guard let data = dayCalories.first(where: { calendar.isDate($0.key, inSameDayAs: key) }),
              data.value.consumed > 0 else {
            return nil
        }
        let diff = abs(data.value.consumed - data.value.goal)
        if diff <= 100 {
            return .green
        } else if diff <= 200 {
            return .yellow
        } else {
            return .red
        }
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

#Preview {
    WeeklyDateStripView(selectedDate: .constant(Date()), dayCalories: [:])
        .padding()
        .background(DesignTokens.Colors.background)
}
