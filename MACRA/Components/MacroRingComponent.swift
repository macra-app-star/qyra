import SwiftUI

struct MacroRingComponent: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let ringColor: Color
    let lineWidth: CGFloat

    init(
        label: String,
        current: Double,
        goal: Double,
        unit: String = "g",
        ringColor: Color = DesignTokens.Colors.ringCalories,
        lineWidth: CGFloat = 8
    ) {
        self.label = label
        self.current = current
        self.goal = goal
        self.unit = unit
        self.ringColor = ringColor
        self.lineWidth = lineWidth
    }

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }

    private var remaining: Double {
        max(goal - current, 0)
    }

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                // Track
                Circle()
                    .stroke(
                        DesignTokens.Colors.ringTrack,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )

                // Progress
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Anim.ring, value: progress)

                // Center label
                VStack(spacing: 2) {
                    Text("\(Int(remaining))")
                        .font(DesignTokens.Typography.monoSmall)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(unit)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(Int(current)) of \(Int(goal)) \(unit), \(Int(progress * 100)) percent")
    }
}

#Preview {
    HStack(spacing: 24) {
        MacroRingComponent(
            label: "Calories",
            current: 1450,
            goal: 2000,
            unit: "cal",
            ringColor: DesignTokens.Colors.ringCalories
        )
        .frame(width: 80, height: 100)

        MacroRingComponent(
            label: "Protein",
            current: 95,
            goal: 150,
            unit: "g",
            ringColor: DesignTokens.Colors.ringProtein
        )
        .frame(width: 80, height: 100)

        MacroRingComponent(
            label: "Carbs",
            current: 160,
            goal: 200,
            unit: "g",
            ringColor: DesignTokens.Colors.ringCarbs
        )
        .frame(width: 80, height: 100)

        MacroRingComponent(
            label: "Fat",
            current: 40,
            goal: 65,
            unit: "g",
            ringColor: DesignTokens.Colors.ringFat
        )
        .frame(width: 80, height: 100)
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
