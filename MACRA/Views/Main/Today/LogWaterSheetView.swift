import SwiftUI

struct LogWaterSheetView: View {
    let viewModel: TodayViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var customAmount: Double = 8

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Current display
            waterDisplay

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

    // MARK: - Water Display

    private var waterDisplay: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .lastTextBaseline, spacing: DesignTokens.Spacing.xs) {
                Text(String(format: "%.0f", viewModel.waterOz))
                    .font(DesignTokens.Typography.numeric(32))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("oz")
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Text("of \(Int(viewModel.waterGoalOz)) oz goal")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DesignTokens.Colors.ringTrack)

                    Capsule()
                        .fill(DesignTokens.Colors.waterBlue)
                        .frame(width: geo.size.width * waterProgress)
                        .animation(DesignTokens.Anim.standard, value: waterProgress)
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
                quickAddButton(label: "1 glass", amount: 8, icon: "cup.and.saucer.fill")
                quickAddButton(label: "1 bottle", amount: 16, icon: "waterbottle.fill")
                quickAddButton(label: "1 large", amount: 24, icon: "takeoutbag.and.cup.and.straw.fill")
            }
        }
    }

    private func quickAddButton(label: String, amount: Int, icon: String) -> some View {
        Button {
            viewModel.logWater(Double(amount))
            DesignTokens.Haptics.light()
            dismiss()
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(QyraFont.regular(20))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                VStack(spacing: 2) {
                    Text(label)
                        .font(DesignTokens.Typography.medium(13))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("\(amount) oz")
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
                    if customAmount > 1 {
                        customAmount -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(QyraFont.regular(28))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                // Amount display
                Text(String(format: "%.0f oz", customAmount))
                    .font(DesignTokens.Typography.numeric(22))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .frame(width: 80)

                // Plus button
                Button {
                    if customAmount < 999 {
                        customAmount += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(QyraFont.regular(28))
                        .foregroundStyle(DesignTokens.Colors.accent)
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
            viewModel.logWater(customAmount)
            DesignTokens.Haptics.light()
            dismiss()
        } label: {
            Text("Log \(Int(customAmount)) oz")
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Layout.buttonHeight)
                .background(DesignTokens.Colors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius))
        }
    }

    // MARK: - Computed

    private var waterProgress: Double {
        guard viewModel.waterGoalOz > 0 else { return 0 }
        return min(viewModel.waterOz / viewModel.waterGoalOz, 1.0)
    }
}

// MARK: - Preview

#Preview {
    LogWaterSheetView(viewModel: {
        let vm = TodayViewModel()
        vm.waterOz = 32
        vm.waterGoalOz = 64
        return vm
    }())
}
