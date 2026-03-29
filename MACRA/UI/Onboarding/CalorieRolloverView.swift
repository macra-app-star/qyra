import SwiftUI

struct CalorieRolloverView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Rollover extra calories to the next day?")
                .padding(.top, DesignTokens.Spacing.lg)

            OnboardingSubtitle(text: "Unused calories from yesterday carry forward to today's budget.")

            Spacer()

            // Clean rollover visualization
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Yesterday → Today flow
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Yesterday
                    dayCard(
                        label: "Yesterday",
                        eaten: 350,
                        goal: 500,
                        remaining: 150,
                        progress: 0.7,
                        isHighlighted: false
                    )

                    // Arrow
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(OnboardingTheme.accent)
                        Text("+150")
                            .font(QyraFont.bold(13))
                            .foregroundStyle(OnboardingTheme.accent)
                    }

                    // Today
                    dayCard(
                        label: "Today",
                        eaten: 0,
                        goal: 650,
                        remaining: 650,
                        progress: 0.0,
                        isHighlighted: true
                    )
                }
                .padding(.horizontal, OnboardingTheme.screenPadding)

                // Explanation
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(OnboardingTheme.accent)
                            .frame(width: 8, height: 8)
                        Text("150 unused cals rolled over")
                            .font(QyraFont.medium(14))
                            .foregroundStyle(OnboardingTheme.textSecondary)
                    }

                    Text("500 base  +  150 rollover  =  650 today")
                        .font(QyraFont.regular(13))
                        .foregroundStyle(OnboardingTheme.textTertiary)
                }
            }

            Spacer()

            // No / Yes buttons
            HStack(spacing: DesignTokens.Layout.itemGap) {
                rolloverButton(label: "No", value: false)
                rolloverButton(label: "Yes", value: true)
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)
            .padding(.bottom, DesignTokens.Layout.sectionGap)
            .padding(.top, DesignTokens.Layout.itemGap)
        }
    }

    // MARK: - Day Card

    private func dayCard(
        label: String,
        eaten: Int,
        goal: Int,
        remaining: Int,
        progress: Double,
        isHighlighted: Bool
    ) -> some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text(label)
                .font(QyraFont.medium(12))
                .foregroundStyle(OnboardingTheme.textSecondary)

            // Ring
            ZStack {
                Circle()
                    .stroke(OnboardingTheme.progressEmpty, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isHighlighted ? OnboardingTheme.accent : OnboardingTheme.textPrimary,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(eaten)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                    Text("/ \(goal)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(OnboardingTheme.textSecondary)
                }
            }
            .frame(width: 80, height: 80)

            Text("\(remaining) left")
                .font(QyraFont.semibold(13))
                .foregroundStyle(isHighlighted ? OnboardingTheme.accent : OnboardingTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(OnboardingTheme.backgroundSecondary)
        )
    }

    // MARK: - Button

    private func rolloverButton(label: String, value: Bool) -> some View {
        Button {
            DesignTokens.Haptics.medium()
            viewModel.calorieRollover = value
            viewModel.advance()
        } label: {
            Text(label)
                .font(QyraFont.semibold(17))
                .foregroundStyle(OnboardingTheme.selectedCardText)
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingTheme.buttonHeight)
                .background(OnboardingTheme.selectedCardBg)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CalorieRolloverView(viewModel: .preview)
}
