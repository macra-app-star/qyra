import SwiftUI

struct TodayMicronutrientsPageView: View {
    let viewModel: TodayViewModel

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // 3 micronutrient cards
            HStack(spacing: DesignTokens.Spacing.sm) {
                microCard(
                    label: "Fiber",
                    consumed: viewModel.fiberConsumed,
                    target: viewModel.fiberTarget,
                    unit: "g",
                    ringColor: DesignTokens.Colors.ringFiber
                )

                microCard(
                    label: "Sugar",
                    consumed: viewModel.sugarConsumed,
                    target: viewModel.sugarTarget,
                    unit: "g",
                    ringColor: DesignTokens.Colors.ringSugar
                )

                microCard(
                    label: "Sodium",
                    consumed: viewModel.sodiumConsumed,
                    target: viewModel.sodiumTarget,
                    unit: "mg",
                    ringColor: DesignTokens.Colors.ringSodium
                )
            }

            // Health Score card
            healthScoreCard
        }
    }

    // MARK: - Micro Card

    private func microCard(
        label: String,
        consumed: Double,
        target: Int,
        unit: String,
        ringColor: Color
    ) -> some View {
        let progress = target > 0 ? min(consumed / Double(target), 1.0) : 0

        return VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(
                        Color(.systemGray5),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )

                Circle()
                    .trim(from: 0, to: min(progress, 1.5))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                Text("\(Int(consumed.rounded()))")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(DesignTokens.Anim.standard, value: consumed)
            }
            .frame(width: 56, height: 56)

            VStack(spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.medium(12))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("/ \(target) \(unit)")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(consumed) of \(target) \(unit), \(Int(progress * 100)) percent")
    }

    // MARK: - Health Score Card

    private var healthScoreCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text("Nutrition Score")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .textCase(nil)
                .kerning(0.5)

        Group {
            if let score = viewModel.healthScore {
                HStack(spacing: DesignTokens.Spacing.lg) {
                    // Circular gauge
                    ZStack {
                        Circle()
                            .stroke(
                                Color(.systemGray5),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )

                        Circle()
                            .trim(from: 0, to: healthScoreProgress)
                            .stroke(
                                DesignTokens.Colors.healthScoreAccent,
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: healthScoreProgress)

                        VStack(spacing: 0) {
                            Text(String(format: "%.0f", score))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                            Text("/ 10")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .frame(width: 100, height: 100)

                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Health Score")
                            .font(DesignTokens.Typography.semibold(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text(healthScoreMessage)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineLimit(3)
                    }

                    Spacer()
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.healthScoreBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            } else {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("No Data")
                        .font(.headline)
                        .foregroundStyle(Color(.label))
                    Text("Log a meal to see your nutrition score.")
                        .font(.subheadline)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.xl)
                .background(DesignTokens.Colors.healthScoreBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
        }
        }
    }

    private var healthScoreProgress: Double {
        guard let score = viewModel.healthScore else { return 0 }
        return score / 10.0
    }

    private var healthScoreMessage: String {
        guard let score = viewModel.healthScore else {
            return "Log meals to see your daily score"
        }
        switch Int(score) {
        case 8...10:
            return "Excellent day! You're crushing your goals."
        case 6...7:
            return "Solid progress. Fine-tune portions to hit your target."
        case 4...5:
            return "Good start! Keep logging meals and staying active."
        default:
            return "Every meal logged is progress. Keep going!"
        }
    }
}

// MARK: - Preview

#Preview {
    TodayMicronutrientsPageView(viewModel: {
        let vm = TodayViewModel()
        vm.fiberConsumed = 18
        vm.fiberTarget = 30
        vm.sugarConsumed = 32
        vm.sugarTarget = 50
        vm.sodiumConsumed = 1400
        vm.sodiumTarget = 2300
        vm.healthScore = 7
        return vm
    }())
    .padding()
    .background(DesignTokens.Colors.background)
}
