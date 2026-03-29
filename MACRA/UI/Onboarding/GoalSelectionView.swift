import SwiftUI

struct GoalSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            OnboardingTitle(text: "What is your goal?")
                .padding(.top, DesignTokens.Spacing.lg)

            // Subtitle
            OnboardingSubtitle(text: "This helps us generate a plan for your macro intake.")

            // Options
            VStack(spacing: OnboardingTheme.optionCardSpacing) {
                OnboardingOptionCard(
                    label: GoalType.cut.onboardingLabel,
                    isSelected: viewModel.goalType == .cut && viewModel.hasSelectedGoal
                ) {
                    viewModel.selectGoal(.cut)
                }

                OnboardingOptionCard(
                    label: GoalType.maintain.onboardingLabel,
                    isSelected: viewModel.goalType == .maintain && viewModel.hasSelectedGoal
                ) {
                    viewModel.selectGoal(.maintain)
                }

                OnboardingOptionCard(
                    label: GoalType.bulk.onboardingLabel,
                    isSelected: viewModel.goalType == .bulk && viewModel.hasSelectedGoal
                ) {
                    viewModel.selectGoal(.bulk)
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)
            .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Continue button
            OnboardingContinueButton(isEnabled: viewModel.hasSelectedGoal) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    GoalSelectionView(viewModel: .preview)
}
