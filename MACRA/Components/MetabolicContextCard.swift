import SwiftUI

struct MetabolicContextCard: View {
    let calorieTarget: Int
    var weightKg: Double?
    var heightCm: Double?
    var age: Int?
    var gender: String?
    var activityLevel: ActivityLevel

    enum ActivityLevel: String, CaseIterable {
        case sedentary = "Sedentary"
        case light = "Lightly Active"
        case moderate = "Moderately Active"
        case active = "Active"
        case veryActive = "Very Active"

        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .active: return 1.725
            case .veryActive: return 1.9
            }
        }
    }

    init(
        calorieTarget: Int,
        weightKg: Double? = nil,
        heightCm: Double? = nil,
        age: Int? = nil,
        gender: String? = nil,
        activityLevel: ActivityLevel = .moderate
    ) {
        self.calorieTarget = calorieTarget
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.age = age
        self.gender = gender
        self.activityLevel = activityLevel
    }

    // MARK: - Computed Values

    /// Mifflin-St Jeor: male = 10*kg + 6.25*cm - 5*age + 5; female = same - 161
    private var bmr: Int {
        let w = weightKg ?? 70.0
        let h = heightCm ?? 170.0
        let a = Double(age ?? 30)
        let isMale = gender?.lowercased() != "female"
        let base = 10.0 * w + 6.25 * h - 5.0 * a
        return Int(isMale ? base + 5 : base - 161)
    }

    private var tdee: Int {
        Int(Double(bmr) * activityLevel.multiplier)
    }

    private var goalAdjustment: Int {
        calorieTarget - tdee
    }

    private var hasProfileData: Bool {
        weightKg != nil && heightCm != nil && age != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: "flame.fill")
                    .font(DesignTokens.Typography.icon(14))
                    .foregroundStyle(Color.orange)

                Text("Metabolic Context")
                    .font(DesignTokens.Typography.semibold(14))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()
            }

            // Breakdown rows
            MetabolicRow(label: "BMR (Mifflin-St Jeor)", value: "\(bmr) cal")
            MetabolicRow(label: "Activity (\(activityLevel.rawValue))", value: "\u{00D7}\(String(format: "%.2f", activityLevel.multiplier))")
            MetabolicRow(label: "TDEE", value: "\(tdee) cal")

            Divider()
                .background(DesignTokens.Colors.border)

            MetabolicRow(
                label: "Goal adjustment",
                value: "\(goalAdjustment > 0 ? "+" : "")\(goalAdjustment) cal",
                valueColor: goalAdjustment < 0 ? DesignTokens.Colors.accent : DesignTokens.Colors.healthGreen
            )
            MetabolicRow(
                label: "Daily target",
                value: "\(calorieTarget) cal",
                isBold: true
            )

            // Footnote
            Text(hasProfileData ? "Based on your profile" : "Based on estimated values")
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .padding(.top, DesignTokens.Spacing.xs)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.background)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Metabolic Row

private struct MetabolicRow: View {
    let label: String
    let value: String
    var valueColor: Color = DesignTokens.Colors.textPrimary
    var isBold: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .font(DesignTokens.Typography.bodyFont(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(isBold ? DesignTokens.Typography.semibold(14) : DesignTokens.Typography.medium(13))
                .foregroundStyle(valueColor)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        MetabolicContextCard(
            calorieTarget: 2000,
            weightKg: 80,
            heightCm: 178,
            age: 30,
            gender: "male",
            activityLevel: .moderate
        )

        MetabolicContextCard(calorieTarget: 1800)
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
