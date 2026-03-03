import SwiftUI

struct NutritionCardComponent: View {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            nutrientColumn(label: "Cal", value: calories, unit: "")
            divider
            nutrientColumn(label: "Protein", value: protein, unit: "g")
            divider
            nutrientColumn(label: "Carbs", value: carbs, unit: "g")
            divider
            nutrientColumn(label: "Fat", value: fat, unit: "g")
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func nutrientColumn(label: String, value: Double, unit: String) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text("\(Int(value))\(unit)")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(DesignTokens.Colors.border)
            .frame(width: 1, height: 32)
    }
}

#Preview {
    NutritionCardComponent(
        calories: 1450,
        protein: 95,
        carbs: 160,
        fat: 40
    )
    .padding()
    .background(DesignTokens.Colors.background)
}
