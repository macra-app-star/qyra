import SwiftUI

struct CoachQuestionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Do you currently work with a personal coach or nutritionist?")
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            VStack(spacing: OnboardingTheme.optionCardSpacing) {
                OnboardingOptionCard(
                    label: "Yes",
                    isSelected: viewModel.hasCoach == true
                ) {
                    viewModel.hasCoach = true
                }

                OnboardingOptionCard(
                    label: "No",
                    isSelected: viewModel.hasCoach == false
                ) {
                    viewModel.hasCoach = false
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            OnboardingContinueButton(
                isEnabled: viewModel.hasCoach != nil
            ) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    CoachQuestionView(viewModel: OnboardingViewModel.preview)
}
