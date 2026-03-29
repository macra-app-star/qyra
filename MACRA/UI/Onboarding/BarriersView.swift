import SwiftUI

struct BarriersView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Title
            OnboardingTitle(text: "What's stopping you from reaching your goals?")
                .padding(.top, DesignTokens.Spacing.lg)

            // Options
            ScrollView(showsIndicators: false) {
                VStack(spacing: OnboardingTheme.optionCardSpacing) {
                    ForEach(Barrier.allCases) { barrier in
                        OnboardingIconOptionCard(
                            icon: barrier.icon,
                            label: barrier.displayName,
                            isSelected: viewModel.barrier == barrier
                        ) {
                            viewModel.barrier = barrier
                        }
                    }
                }
                .padding(.horizontal, OnboardingTheme.screenPadding)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Layout.cardGap)
            }

            Spacer()

            // Continue button
            OnboardingContinueButton(isEnabled: viewModel.barrier != nil) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    BarriersView(viewModel: .preview)
}
