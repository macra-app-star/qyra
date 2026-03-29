import SwiftUI

struct AccomplishView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "What do you want to accomplish?")
                .padding(.top, DesignTokens.Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingTheme.optionCardSpacing) {
                    ForEach(Accomplishment.allCases) { item in
                        OnboardingIconOptionCard(
                            icon: item.icon,
                            label: item.displayName,
                            isSelected: viewModel.accomplishment == item
                        ) {
                            viewModel.accomplishment = item
                        }
                    }
                }
                .padding(.horizontal, OnboardingTheme.screenPadding)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Layout.cardGap)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: viewModel.accomplishment != nil) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    AccomplishView(viewModel: .preview)
}
