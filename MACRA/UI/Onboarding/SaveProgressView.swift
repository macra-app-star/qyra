import SwiftUI

struct SaveProgressView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(OnboardingTheme.accent.opacity(0.12))
                        .frame(width: 80, height: 80)

                    Image(systemName: "arrow.down.doc")
                        .font(QyraFont.medium(32))
                        .foregroundStyle(OnboardingTheme.accent)
                }

                Text("Save your progress")
                    .font(OnboardingTheme.titleFont)
                    .tracking(OnboardingTheme.titleTracking)
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Create an account to keep your personalized plan and track your progress across devices.")
                    .font(OnboardingTheme.subtitleFont)
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Layout.itemGap)
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            // Auth buttons
            VStack(spacing: 14) {
                // Sign in with Apple
                authButton(
                    icon: {
                        Image(systemName: "apple.logo")
                            .font(QyraFont.regular(20))
                            .foregroundStyle(.white)
                    },
                    label: "Sign in with Apple",
                    labelColor: .white,
                    background: OnboardingTheme.selectedCardBg,
                    borderColor: .clear
                ) {
                    Task {
                        let success = await AuthService.shared.signIn()
                        if success { viewModel.advance() }
                    }
                }

                // Sign in with Google
                authButton(
                    icon: {
                        Text("G")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .red, .yellow, .green],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    },
                    label: "Sign in with Google",
                    labelColor: OnboardingTheme.textPrimary,
                    background: .white,
                    borderColor: OnboardingTheme.divider
                ) {
                    // Google sign-in — not yet configured, skip to next step
                    viewModel.advance()
                }

                // Continue with email
                authButton(
                    icon: {
                        Image(systemName: "envelope")
                            .font(QyraFont.regular(20))
                            .foregroundStyle(OnboardingTheme.textPrimary)
                    },
                    label: "Continue with email",
                    labelColor: OnboardingTheme.textPrimary,
                    background: .white,
                    borderColor: OnboardingTheme.divider
                ) {
                    // Email sign-in — not yet configured, skip to next step
                    viewModel.advance()
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            // Skip button
            Button {
                viewModel.advance()
            } label: {
                Text("Skip for now")
                    .font(QyraFont.medium(15))
                    .foregroundStyle(OnboardingTheme.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.top, DesignTokens.Layout.cardGap)
            .padding(.bottom, DesignTokens.Layout.sectionGap)
        }
    }

    // MARK: - Auth Button

    private func authButton<Icon: View>(
        icon: () -> Icon,
        label: String,
        labelColor: Color,
        background: Color,
        borderColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Layout.itemGap) {
                icon()

                Text(label)
                    .font(OnboardingTheme.buttonFont)
                    .foregroundStyle(labelColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.buttonHeight)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius)
                    .stroke(borderColor, lineWidth: borderColor == .clear ? 0 : 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SaveProgressView(viewModel: .preview)
}
