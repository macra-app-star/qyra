import SwiftUI

struct WorkoutFrequencyView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "How many workouts do you do per week?")
                .padding(.top, DesignTokens.Spacing.lg)

            OnboardingSubtitle(text: "This will be used to calibrate your custom plan.")

            VStack(spacing: OnboardingTheme.optionCardSpacing) {
                ForEach(WorkoutFrequency.allCases) { frequency in
                    Button {
                        DesignTokens.Haptics.selection()
                        viewModel.workoutFrequency = frequency
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(frequency.title)
                                .font(OnboardingTheme.cardLabelFont)
                                .foregroundStyle(viewModel.workoutFrequency == frequency ? OnboardingTheme.selectedCardText : OnboardingTheme.textPrimary)
                            if !frequency.subtitle.isEmpty {
                                Text(frequency.subtitle)
                                    .font(QyraFont.regular(14))
                                    .foregroundStyle(viewModel.workoutFrequency == frequency ? OnboardingTheme.selectedCardText.opacity(0.7) : OnboardingTheme.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, OnboardingTheme.cardPadding)
                        .padding(.vertical, 18)
                        .background(viewModel.workoutFrequency == frequency ? OnboardingTheme.selectedCardBg : OnboardingTheme.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
                    }
                    .buttonStyle(.plain)
                    .animation(OnboardingTheme.quickSpring, value: viewModel.workoutFrequency)
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)
            .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    WorkoutFrequencyView(viewModel: .preview)
}
