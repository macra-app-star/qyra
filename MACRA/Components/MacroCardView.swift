import SwiftUI

struct MacroCardView: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    private var remaining: Double {
        max(goal - current, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Label with colored dot
            HStack(spacing: DesignTokens.Spacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // Current value
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(Int(current))")
                    .font(DesignTokens.Typography.numeric(22))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .contentTransition(.numericText())
                Text(unit)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // Goal
            Text("of \(Int(goal))\(unit)")
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.Colors.ringTrack)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(DesignTokens.Anim.ring, value: progress)
                }
            }
            .frame(height: 6)
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Int(current)) of \(Int(goal)) \(unit), \(Int(progress * 100)) percent")
    }
}

#Preview {
    HStack(spacing: DesignTokens.Layout.itemGap) {
        MacroCardView(label: "Protein", current: 95, goal: 150, unit: "g", color: DesignTokens.Colors.protein)
        MacroCardView(label: "Carbs", current: 160, goal: 200, unit: "g", color: DesignTokens.Colors.carbs)
        MacroCardView(label: "Fat", current: 40, goal: 65, unit: "g", color: DesignTokens.Colors.fat)
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
