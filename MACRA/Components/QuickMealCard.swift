import SwiftUI

struct QuickMealCard: View {
    let meal: QuickMeal
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: DesignTokens.Layout.microGap) {
                Text(meal.name)
                    .font(DesignTokens.Typography.medium(13))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Text("\(Int(meal.totalCalories)) cal")
                    .font(DesignTokens.Typography.semibold(12))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .padding(DesignTokens.Layout.tightGap + 2)
            .frame(width: 140, height: 80, alignment: .topLeading)
            .premiumCard(cornerRadius: DesignTokens.Radius.md, elevation: .subtle)
        }
        .buttonStyle(QuickMealButtonStyle())
    }
}

// MARK: - Button Style

private struct QuickMealButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.default, value: configuration.isPressed)
    }
}

#Preview {
    HStack {
        QuickMealCard(
            meal: QuickMeal(
                name: "Morning eggs & toast",
                foodItems: [],
                totalCalories: 420,
                totalProtein: 28,
                totalCarbs: 35,
                totalFat: 18,
                typicalHour: 8,
                logCount: 5
            )
        ) { }

        QuickMealCard(
            meal: QuickMeal(
                name: "Afternoon protein shake with banana",
                foodItems: [],
                totalCalories: 310,
                totalProtein: 32,
                totalCarbs: 28,
                totalFat: 8,
                typicalHour: 15,
                logCount: 3
            )
        ) { }
    }
    .padding()
}
