import SwiftUI

struct BMICardSection: View {
    let bmi: Double?
    let formattedBMI: String
    let category: String

    private var categoryColor: Color {
        switch category {
        case "Underweight": return DesignTokens.Colors.bmiBlue
        case "Normal": return DesignTokens.Colors.bmiGreen
        case "Overweight": return DesignTokens.Colors.bmiYellow
        case "Obese": return DesignTokens.Colors.bmiRed
        default: return DesignTokens.Colors.textTertiary
        }
    }

    /// Maps BMI value to a 0-1 position on the gradient bar.
    /// Scale: 15 (0.0) to 40 (1.0)
    private var indicatorPosition: Double {
        guard let bmi else { return 0 }
        let clamped = min(max(bmi, 15), 40)
        return (clamped - 15) / 25
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("BMI")
                .font(DesignTokens.Typography.headlineFont(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(spacing: DesignTokens.Spacing.md) {
                // BMI value + category
                HStack(alignment: .firstTextBaseline) {
                    Text(formattedBMI)
                        .font(DesignTokens.Typography.numeric(36))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    if bmi != nil {
                        Text(category)
                            .font(DesignTokens.Typography.medium(13))
                            .foregroundStyle(categoryColor)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(categoryColor.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                // Gradient bar with indicator
                if bmi != nil {
                    bmiGradientBar
                } else {
                    emptyGradientBar
                }

                // Scale labels
                HStack {
                    Text("15")
                    Spacer()
                    Text("18.5")
                    Spacer()
                    Text("25")
                    Spacer()
                    Text("30")
                    Spacer()
                    Text("40")
                }
                .font(DesignTokens.Typography.bodyFont(10))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private var bmiGradientBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Gradient bar
                LinearGradient(
                    colors: [
                        DesignTokens.Colors.bmiBlue,
                        DesignTokens.Colors.bmiGreen,
                        DesignTokens.Colors.bmiYellow,
                        DesignTokens.Colors.bmiRed
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 8)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                // Triangle indicator
                let xPos = geo.size.width * indicatorPosition
                Triangle()
                    .fill(DesignTokens.Colors.textPrimary)
                    .frame(width: 12, height: 8)
                    .offset(x: xPos - 6, y: -10)
            }
        }
        .frame(height: 20)
    }

    private var emptyGradientBar: some View {
        LinearGradient(
            colors: [
                DesignTokens.Colors.bmiBlue.opacity(0.35),
                DesignTokens.Colors.bmiGreen.opacity(0.35),
                DesignTokens.Colors.bmiYellow.opacity(0.35),
                DesignTokens.Colors.bmiRed.opacity(0.35)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 8)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        // Empty state
        BMICardSection(
            bmi: nil,
            formattedBMI: "\u{2014}",
            category: "Unknown"
        )

        // Normal BMI
        BMICardSection(
            bmi: 22.4,
            formattedBMI: "22.4",
            category: "Normal"
        )

        // Overweight BMI
        BMICardSection(
            bmi: 27.1,
            formattedBMI: "27.1",
            category: "Overweight"
        )
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
