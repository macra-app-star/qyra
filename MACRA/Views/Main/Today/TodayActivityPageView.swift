import SwiftUI

struct TodayActivityPageView: View {
    let viewModel: TodayViewModel
    var onLogWater: () -> Void
    var onLogCaffeine: () -> Void

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Steps + Calories Burned row
            HStack(spacing: DesignTokens.Spacing.sm) {
                stepsCard
                caloriesBurnedCard
            }

            // Water card
            waterCard

            // Caffeine card
            caffeineCard
        }
    }

    // MARK: - Steps Card

    private var stepsCard: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(
                        Color(.systemGray5),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )

                Circle()
                    .trim(from: 0, to: min(stepsProgress, 1.5))
                    .stroke(
                        DesignTokens.Colors.accent,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: stepsProgress)

                Image(systemName: "figure.walk")
                    .font(QyraFont.medium(18))
                    .foregroundStyle(DesignTokens.Colors.accent)
            }
            .frame(width: 56, height: 56)
            .ringPulse(trigger: viewModel.steps)

            VStack(spacing: 2) {
                Text(formattedSteps)
                    .font(DesignTokens.Typography.numeric(20))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .numericTransition(value: viewModel.steps)

                Text("/ \(formattedGoal) steps")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Steps: \(viewModel.steps) of \(viewModel.stepsGoal)")
    }

    // MARK: - Calories Burned Card

    private var caloriesBurnedCard: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.surface)
                    .frame(width: 56, height: 56)

                Image(systemName: "flame.fill")
                    .font(QyraFont.medium(22))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 2) {
                Text("\(viewModel.caloriesBurned)")
                    .font(DesignTokens.Typography.numeric(20))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .numericTransition(value: viewModel.caloriesBurned)

                Text("cal burned")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Calories burned: \(viewModel.caloriesBurned)")
    }

    // MARK: - Water Card

    private var waterCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Water icon + amount
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "drop.fill")
                    .font(QyraFont.regular(22))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.0f oz", viewModel.waterOz))
                        .font(DesignTokens.Typography.numeric(22))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(DesignTokens.Anim.standard, value: viewModel.waterOz)

                    Text("/ \(Int(viewModel.waterGoalOz)) oz goal")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Spacer()

            // Progress bar
            waterProgressBar

            Spacer()

            // Log Water button
            Button {
                onLogWater()
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "plus")
                        .font(QyraFont.bold(12))

                    Text("Log")
                        .font(DesignTokens.Typography.semibold(13))
                }
                .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(DesignTokens.Colors.buttonPrimary)
                .clipShape(Capsule())
            }
        }
        .premiumCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Water: \(Int(viewModel.waterOz)) of \(Int(viewModel.waterGoalOz)) ounces")
    }

    private var waterProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * waterProgress, height: 8)
                    .animation(DesignTokens.Anim.standard, value: waterProgress)
            }
        }
        .frame(width: 60, height: 8)
    }

    // MARK: - Caffeine Card

    private var caffeineCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Caffeine icon + amount
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(QyraFont.regular(20))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(Int(viewModel.caffeineMg)) mg")
                        .font(DesignTokens.Typography.numeric(22))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(DesignTokens.Anim.standard, value: viewModel.caffeineMg)

                    Text("/ \(Int(viewModel.caffeineGoalMg)) mg limit")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Spacer()

            // Progress bar
            caffeineProgressBar

            Spacer()

            // Log Caffeine button
            Button {
                onLogCaffeine()
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "plus")
                        .font(QyraFont.bold(12))

                    Text("Log")
                        .font(DesignTokens.Typography.semibold(13))
                }
                .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
        }
        .premiumCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Caffeine: \(Int(viewModel.caffeineMg)) of \(Int(viewModel.caffeineGoalMg)) milligrams")
    }

    private var caffeineProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 8)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * caffeineProgress, height: 8)
                    .animation(DesignTokens.Anim.standard, value: caffeineProgress)
            }
        }
        .frame(width: 60, height: 8)
    }

    // MARK: - Computed

    private var stepsProgress: Double {
        guard viewModel.stepsGoal > 0 else { return 0 }
        return min(Double(viewModel.steps) / Double(viewModel.stepsGoal), 1.0)
    }

    private var waterProgress: Double {
        guard viewModel.waterGoalOz > 0 else { return 0 }
        return min(viewModel.waterOz / viewModel.waterGoalOz, 1.0)
    }

    private var caffeineProgress: Double {
        guard viewModel.caffeineGoalMg > 0 else { return 0 }
        return min(viewModel.caffeineMg / viewModel.caffeineGoalMg, 1.0)
    }

    private var formattedSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: viewModel.steps)) ?? "\(viewModel.steps)"
    }

    private var formattedGoal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: viewModel.stepsGoal)) ?? "\(viewModel.stepsGoal)"
    }
}

// MARK: - Preview

#Preview {
    TodayActivityPageView(
        viewModel: {
            let vm = TodayViewModel()
            vm.steps = 6543
            vm.stepsGoal = 10_000
            vm.caloriesBurned = 287
            vm.waterOz = 40
            vm.waterGoalOz = 64
            vm.caffeineMg = 190
            vm.caffeineGoalMg = 400
            return vm
        }(),
        onLogWater: {},
        onLogCaffeine: {}
    )
    .padding()
    .background(DesignTokens.Colors.background)
}
