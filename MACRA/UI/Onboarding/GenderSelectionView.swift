import SwiftUI

struct GenderSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            OnboardingTitle(text: "Choose your Gender")
                .padding(.top, DesignTokens.Spacing.lg)

            // Subtitle
            OnboardingSubtitle(text: "This will be used to calibrate your custom plan.")

            // Options
            VStack(spacing: DesignTokens.Layout.itemGap) {
                ForEach(Gender.allCases) { gender in
                    OnboardingOptionCard(
                        label: gender.displayName,
                        isSelected: viewModel.gender == gender
                    ) {
                        viewModel.gender = gender
                    }
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)
            .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Continue button
            OnboardingContinueButton(isEnabled: viewModel.gender != nil) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    GenderSelectionView(viewModel: .preview)
}
