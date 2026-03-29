import SwiftUI

struct RatingPromptView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(OnboardingTheme.accent)

                Text("You're all set")
                    .font(OnboardingTheme.titleFont)
                    .tracking(OnboardingTheme.titleTracking)
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Your personalized plan is ready.\nLet's get started.")
                    .font(QyraFont.regular(16))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            OnboardingContinueButton(label: "Start tracking", isEnabled: true) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    RatingPromptView(viewModel: .preview)
}
