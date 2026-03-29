import SwiftUI

struct HealthScoreInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let factors: [(icon: String, title: String, weight: String, description: String)] = [
        ("target", "Calorie Goal Adherence", "40%", "How closely your daily intake matches your target."),
        ("chart.pie.fill", "Macro Balance", "30%", "The ratio of protein, carbs, and fat relative to your goals."),
        ("leaf.fill", "Micronutrient Completeness", "20%", "Coverage of essential vitamins and minerals."),
        ("calendar.badge.checkmark", "Meal Logging Consistency", "10%", "How regularly you log meals each day.")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Your Health Score is a composite metric based on four factors:")
                        .font(DesignTokens.Typography.bodyFont(15))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    ForEach(factors, id: \.title) { factor in
                        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                            Image(systemName: factor.icon)
                                .font(DesignTokens.Typography.icon(20))
                                .foregroundStyle(DesignTokens.Colors.brandAccent)
                                .frame(width: 28)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(factor.title)
                                        .font(DesignTokens.Typography.semibold(15))
                                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                                    Spacer()
                                    Text(factor.weight)
                                        .font(DesignTokens.Typography.semibold(15))
                                        .foregroundStyle(DesignTokens.Colors.brandAccent)
                                }
                                Text(factor.description)
                                    .font(DesignTokens.Typography.bodyFont(13))
                                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                            }
                        }
                        .padding(DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }

                    Text("This is not a medical assessment. Consult a healthcare professional for medical advice.")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DesignTokens.Spacing.sm)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xl)
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Health Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HealthScoreInfoSheet()
}
