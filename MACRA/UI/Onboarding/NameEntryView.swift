import SwiftUI

struct NameEntryView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("What's your first name?")
                    .font(OnboardingTheme.titleFont)
                    .tracking(OnboardingTheme.titleTracking)
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("We'll use this to personalize your experience.")
                    .font(OnboardingTheme.subtitleFont)
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("First name", text: $viewModel.firstName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(viewModel.firstName.isEmpty ? OnboardingTheme.progressEmpty : Color.accentColor)
                            .frame(height: 2)
                    }
                    .focused($isFocused)
                    .textContentType(.givenName)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()
            Spacer()

            OnboardingContinueButton(
                isEnabled: !viewModel.firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ) {
                isFocused = false
                viewModel.advance()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    NameEntryView(viewModel: .preview)
}
