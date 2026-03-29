import SwiftUI

struct AttributionSourceView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Where did you hear about us?")
                .padding(.top, DesignTokens.Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingTheme.optionCardSpacing) {
                    ForEach(ReferralSource.allCases) { source in
                        OnboardingOptionCard(
                            label: source.displayName,
                            isSelected: viewModel.referralSource == source
                        ) {
                            viewModel.referralSource = source
                        }
                    }
                }
                .padding(.horizontal, OnboardingTheme.screenPadding)
                .padding(.top, DesignTokens.Layout.cardGap)
                .padding(.bottom, DesignTokens.Layout.cardGap)
            }

            Spacer()

            OnboardingContinueButton(
                isEnabled: viewModel.referralSource != nil
            ) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    AttributionSourceView(viewModel: OnboardingViewModel.preview)
}
