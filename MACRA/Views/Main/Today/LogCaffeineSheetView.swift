import SwiftUI

struct LogCaffeineSheetView: View {
    let viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customAmount: Double = 95

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Current display
            caffeineDisplay

            // Quick add buttons
            quickAddButtons

            // Custom stepper
            customStepper

            // Log CTA
            logButton
                .padding(.top, DesignTokens.Spacing.md)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.xl)
        .padding(.bottom, DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.background)
    }

    // MARK: - Caffeine Display

    private var caffeineDisplay: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .lastTextBaseline, spacing: DesignTokens.Spacing.xs) {
                Text("\(Int(viewModel.caffeineMg))")
                    .font(DesignTokens.Typography.numeric(32))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("mg")
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Text("of \(Int(viewModel.caffeineGoalMg)) mg daily limit")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignTokens.Colors.ringTrack)

                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geo.size.width * caffeineProgress)
                        .animation(DesignTokens.Anim.standard, value: caffeineProgress)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, DesignTokens.Spacing.xl)
            .padding(.top, DesignTokens.Spacing.sm)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }

    // MARK: - Quick Add Buttons

    private var quickAddButtons: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text("Quick Add")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DesignTokens.Spacing.sm) {
                quickAddButton(label: "Espresso", amount: 63, icon: "cup.and.saucer.fill")
                quickAddButton(label: "Coffee", amount: 95, icon: "mug.fill")
                quickAddButton(label: "Energy", amount: 160, icon: "bolt.fill")
            }
        }
    }

    private func quickAddButton(label: String, amount: Int, icon: String) -> some View {
        Button {
            viewModel.logCaffeine(Double(amount))
            DesignTokens.Haptics.light()
            dismiss()
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(QyraFont.regular(20))
                    .foregroundStyle(Color.secondary)

                VStack(spacing: 2) {
                    Text(label)
                        .font(DesignTokens.Typography.medium(13))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("\(amount) mg")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Custom Stepper

    private var customStepper: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text("Custom Amount")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: DesignTokens.Spacing.lg) {
                // Minus button
                Button {
                    if customAmount > 5 {
                        customAmount -= 5
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(QyraFont.regular(28))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                // Amount display
                Text("\(Int(customAmount)) mg")
                    .font(DesignTokens.Typography.numeric(22))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .frame(width: 80)

                // Plus button
                Button {
                    if customAmount < 999 {
                        customAmount += 5
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(QyraFont.regular(28))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button {
            viewModel.logCaffeine(customAmount)
            DesignTokens.Haptics.light()
            dismiss()
        } label: {
            Text("Log \(Int(customAmount)) mg")
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Layout.buttonHeight)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius))
        }
    }

    // MARK: - Computed

    private var caffeineProgress: Double {
        guard viewModel.caffeineGoalMg > 0 else { return 0 }
        return min(viewModel.caffeineMg / viewModel.caffeineGoalMg, 1.0)
    }
}

// MARK: - Preview

#Preview {
    LogCaffeineSheetView(viewModel: {
        let vm = TodayViewModel()
        vm.caffeineMg = 190
        vm.caffeineGoalMg = 400
        return vm
    }())
}
