import SwiftUI

struct MotivationView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Center content
            VStack(spacing: 0) {
                motivationText
                    .padding(.horizontal, DesignTokens.Spacing.xl)

                Text("Stay consistent with your plan and the results will follow.")
                    .font(QyraFont.regular(15))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, DesignTokens.Layout.cardGap)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }

            Spacer()

            // Continue button
            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }

    // MARK: - Motivation Text

    private var motivationText: some View {
        let delta = viewModel.weightDifferenceDisplay
        let unit = viewModel.weightUnit
        let verb = viewModel.goalActionVerb

        return VStack(spacing: 0) {
            (
                Text(verb.isEmpty ? "" : "\(verb) ")
                    .font(QyraFont.bold(32))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                +
                Text("\(Int(delta)) \(unit)")
                    .font(QyraFont.bold(32))
                    .foregroundStyle(OnboardingTheme.accent)
                +
                Text(" is a realistic target. You've got this.")
                    .font(QyraFont.bold(32))
                    .foregroundStyle(OnboardingTheme.textPrimary)
            )
            .tracking(-0.8)
            .lineSpacing(6)
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    MotivationView(viewModel: .preview)
}
