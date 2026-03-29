import SwiftUI

struct TodayMacrosPageView: View {
    let viewModel: TodayViewModel
    @State private var hasTriggeredTargetHaptic = false
    @State private var showMetabolicContext = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Large calorie card
            calorieCard

            // 3 macro cards
            HStack(spacing: DesignTokens.Spacing.sm) {
                macroCard(
                    label: "Protein",
                    consumed: viewModel.proteinConsumed,
                    target: viewModel.proteinTarget,
                    ringColor: DesignTokens.Colors.ringProtein
                )

                macroCard(
                    label: "Carbs",
                    consumed: viewModel.carbsConsumed,
                    target: viewModel.carbsTarget,
                    ringColor: DesignTokens.Colors.ringCarbs
                )

                macroCard(
                    label: "Fat",
                    consumed: viewModel.fatConsumed,
                    target: viewModel.fatTarget,
                    ringColor: DesignTokens.Colors.ringFat
                )
            }
        }
    }

    // MARK: - Calorie Card (Body Budget)

    private var calorieCard: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Spacer()

                ZStack {
                    // Track ring — faint systemGray5
                    Circle()
                        .stroke(
                            Color(.systemGray5),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )

                    // Progress ring — solid color, Apple Activity Ring style
                    Circle()
                        .trim(from: 0, to: budgetRingProgress)
                        .stroke(
                            DesignTokens.Colors.calorieRing,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: budgetRingProgress)

                    // Center content — consumed count + "of X budget"
                    VStack(spacing: DesignTokens.Spacing.xxs) {
                        Text("\(viewModel.caloriesConsumed)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                            .contentTransition(.numericText())
                            .animation(DesignTokens.Anim.standard, value: viewModel.caloriesConsumed)

                        Button {
                            withAnimation(DesignTokens.Anim.spring) {
                                showMetabolicContext.toggle()
                            }
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Text("of \(viewModel.calorieTarget) cals")
                                    .font(DesignTokens.Typography.label(11))
                                    .foregroundStyle(Color(.secondaryLabel))

                                Image(systemName: "info.circle")
                                    .font(DesignTokens.Typography.icon(10))
                                    .foregroundStyle(Color(.tertiaryLabel))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 160, height: 160)
                .ringPulse(trigger: viewModel.caloriesConsumed)

                Spacer()

                // Side info — Body Budget framing
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    calorieDetailRow(
                        label: "consumed",
                        value: "\(viewModel.caloriesConsumed)",
                        color: DesignTokens.Colors.textPrimary
                    )
                    calorieDetailRow(
                        label: "daily cals",
                        value: "\(viewModel.calorieTarget)",
                        color: DesignTokens.Colors.textSecondary
                    )
                    calorieDetailRow(
                        label: "earned back",
                        value: "\(viewModel.caloriesBurned)",
                        color: viewModel.caloriesBurned > 0 ? DesignTokens.Colors.accent : Color(.secondaryLabel)
                    )
                }

                Spacer()
            }

            // Metabolic context (shown on info tap)
            if showMetabolicContext {
                MetabolicContextCard(calorieTarget: viewModel.calorieTarget)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .premiumCard(elevation: .elevated)
        .onChange(of: viewModel.caloriesConsumed) { _, newValue in
            let ratio = viewModel.calorieTarget > 0
                ? Double(newValue) / Double(viewModel.calorieTarget)
                : 0
            if ratio >= 1.0 && !hasTriggeredTargetHaptic {
                hasTriggeredTargetHaptic = true
                DesignTokens.Haptics.success()
            }
        }
    }

    private func calorieDetailRow(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .animation(DesignTokens.Anim.standard, value: value)

            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Body Budget Ring

    /// Ring fills clockwise from 0 toward target — overfill up to 150%
    private var budgetRingProgress: Double {
        guard viewModel.calorieTarget > 0 else { return 0 }
        return min(Double(viewModel.caloriesConsumed) / Double(viewModel.calorieTarget), 1.5)
    }

    // MARK: - Macro Card

    private func macroCard(
        label: String,
        consumed: Int,
        target: Int,
        ringColor: Color
    ) -> some View {
        let progress = target > 0 ? Double(consumed) / Double(target) : 0

        return VStack(spacing: DesignTokens.Spacing.sm) {
            // Small ring — Apple Activity Ring style
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

                Text("\(consumed)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .contentTransition(.numericText())
                    .animation(DesignTokens.Anim.standard, value: consumed)
            }
            .frame(width: 56, height: 56)

            // Label and target
            VStack(spacing: 2) {
                Text(label)
                    .font(DesignTokens.Typography.medium(12))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("/ \(target) g")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(consumed) of \(target) grams, \(Int(min(progress, 1.0) * 100)) percent")
    }
}

// MARK: - Preview

#Preview {
    TodayMacrosPageView(viewModel: {
        let vm = TodayViewModel()
        vm.calorieTarget = 2000
        vm.caloriesConsumed = 1450
        vm.proteinConsumed = 95
        vm.proteinTarget = 150
        vm.carbsConsumed = 160
        vm.carbsTarget = 250
        vm.fatConsumed = 40
        vm.fatTarget = 65
        vm.caloriesBurned = 320
        return vm
    }())
    .padding()
    .background(DesignTokens.Colors.background)
}
