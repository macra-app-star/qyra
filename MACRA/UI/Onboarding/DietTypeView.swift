import SwiftUI

struct DietTypeView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Do you follow a specific diet?")
                .padding(.top, DesignTokens.Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingTheme.optionCardSpacing) {
                    ForEach(DietType.allCases) { diet in
                        OnboardingIconOptionCard(
                            icon: diet.icon,
                            label: diet.displayName,
                            isSelected: viewModel.dietType == diet
                        ) {
                            viewModel.dietType = diet
                        }
                    }
                }
                .padding(.horizontal, OnboardingTheme.screenPadding)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Layout.cardGap)
            }

            OnboardingContinueButton(isEnabled: viewModel.dietType != nil) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    DietTypeView(viewModel: .preview)
}
