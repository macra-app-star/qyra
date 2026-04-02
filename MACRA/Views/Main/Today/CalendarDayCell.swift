import SwiftUI

struct CalendarStatusColors {
    // DESIGN SYSTEM EXCEPTION: Calendar day status indicator colors.
    // Traffic-light semantics for nutritional adherence.
    static let loggedGreen = Color(red: 0.298, green: 0.686, blue: 0.314)   // #4CAF50
    static let graceDayAmber = Color(red: 0.961, green: 0.773, blue: 0.259) // #F5C542
    static let missedRed = Color(red: 0.898, green: 0.224, blue: 0.208)     // #E53935
    static let noDataGray = Color(.systemGray4)
}

struct CalendarDayCell: View {
    let day: CalendarDay
    let status: DayStatus?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Date number
                ZStack {
                    if day.isToday {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 28, height: 28)
                    }

                    Text("\(day.dayNumber)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            day.isToday ? .white :
                            day.isCurrentMonth ? Color(.label) : Color(.quaternaryLabel)
                        )
                }
                .frame(width: 28, height: 28)

                // Status indicator
                if day.isCurrentMonth {
                    statusIndicator
                        .frame(width: 24, height: 24)
                } else {
                    Color.clear
                        .frame(width: 24, height: 24)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .logged:
            ZStack {
                Circle()
                    .fill(CalendarStatusColors.loggedGreen)
                Image(systemName: "flame.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
            }

        case .graceDay:
            ZStack {
                Circle()
                    .fill(CalendarStatusColors.graceDayAmber)

                // Green checkmark badge at bottom-right
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(CalendarStatusColors.loggedGreen)
                                .frame(width: 12, height: 12)
                            Image(systemName: "checkmark")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .offset(x: 3, y: 3)
                    }
                }
            }

        case .missed:
            ZStack {
                Circle()
                    .fill(CalendarStatusColors.missedRed)
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
            }

        case .future:
            ZStack {
                Circle()
                    .fill(CalendarStatusColors.noDataGray.opacity(0.3))
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(.secondaryLabel).opacity(0.3))
            }

        case nil:
            ZStack {
                Circle()
                    .fill(CalendarStatusColors.noDataGray.opacity(0.3))
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(.secondaryLabel).opacity(0.3))
            }
        }
    }
}
