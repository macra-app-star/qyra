import SwiftUI

struct PreviousAppsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Have you tried other nutrition tracking apps?")
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            VStack(spacing: OnboardingTheme.optionCardSpacing) {
                OnboardingOptionCard(
                    label: "Yes",
                    isSelected: viewModel.hasTriedOtherApps == true
                ) {
                    viewModel.hasTriedOtherApps = true
                }

                OnboardingOptionCard(
                    label: "No",
                    isSelected: viewModel.hasTriedOtherApps == false
                ) {
                    viewModel.hasTriedOtherApps = false
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            OnboardingContinueButton(
                isEnabled: viewModel.hasTriedOtherApps != nil
            ) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    PreviousAppsView(viewModel: OnboardingViewModel.preview)
}
