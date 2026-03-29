import SwiftUI

struct ReferralCodeView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Title
            OnboardingTitle(text: "Enter referral code (optional)")
                .padding(.top, DesignTokens.Spacing.lg)

            // Subtitle
            OnboardingSubtitle(text: "You can skip this step")

            Spacer()

            // Text field with submit button
            referralTextField
                .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            // Skip button (dark style)
            OnboardingContinueButton(label: "Skip", isEnabled: true) {
                isFieldFocused = false
                viewModel.advance()
            }
        }
        .onTapGesture {
            isFieldFocused = false
        }
    }

    // MARK: - Referral Text Field

    private var referralTextField: some View {
        HStack(spacing: 0) {
            TextField("Referral Code", text: $viewModel.referralCode)
                .font(QyraFont.regular(16))
                .foregroundStyle(OnboardingTheme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .focused($isFieldFocused)
                .padding(.leading, DesignTokens.Spacing.lg)

            Button {
                isFieldFocused = false
                if !viewModel.referralCode.isEmpty {
                    viewModel.advance()
                }
            } label: {
                Text("Submit")
                    .font(QyraFont.semibold(15))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, 10)
                    .background(OnboardingTheme.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(height: 56)
        .background(OnboardingTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ReferralCodeView(viewModel: .preview)
}
