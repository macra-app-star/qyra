import SwiftUI
import SwiftData

struct RecentlyUploadedSection: View {
    let meals: [RecentMealItem]
    var mealSummaries: [UUID: MealSummary] = [:]
    var modelContainer: ModelContainer? = nil
    var onDelete: ((UUID) -> Void)? = nil
    var onRefresh: (() -> Void)? = nil
    var onLogMeal: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Section header
            HStack {
                Text("Today's meals")
                    .font(DesignTokens.Typography.semibold(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()
            }

            if meals.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(meals) { meal in
                        Group {
                            if let summary = mealSummaries[meal.id], modelContainer != nil {
                                NavigationLink(value: summary) {
                                    mealRowContent(meal)
                                }
                            } else {
                                mealRowContent(meal)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                onDelete?(meal.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(DesignTokens.Colors.surfaceElevated)
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .frame(height: CGFloat(meals.count) * 52)
                .background(DesignTokens.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
        }
    }

    // MARK: - Meal Row Content

    private func mealRowContent(_ meal: RecentMealItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Emoji
                Text(meal.emoji)
                    .font(QyraFont.regular(20))
                    .frame(width: 32, height: 32)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

                // Name + time
                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.name)
                        .font(DesignTokens.Typography.medium(14))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(timeString(meal.time))
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                Spacer()

                // Calories
                Text("\(meal.calories) cal")
                    .font(DesignTokens.Typography.label(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm + 2)

            if meal.id != meals.last?.id {
                Divider()
                    .foregroundStyle(DesignTokens.Colors.separator)
                    .padding(.leading, 44)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        EmptyDataView(
            title: "No Meals Logged",
            subtitle: "Scan your food to get started.",
            actionTitle: "Scan Food",
            action: {
                onLogMeal?()
            }
        )
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Helpers

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        RecentlyUploadedSection(meals: [
            RecentMealItem(id: UUID(), name: "Greek Yogurt with Berries", calories: 280, time: Date(), emoji: "🥣"),
            RecentMealItem(id: UUID(), name: "Grilled Chicken Salad", calories: 420, time: Date().addingTimeInterval(-3600), emoji: "🥗"),
            RecentMealItem(id: UUID(), name: "Protein Bar", calories: 210, time: Date().addingTimeInterval(-7200), emoji: "🍎"),
        ])

        RecentlyUploadedSection(meals: [])
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
