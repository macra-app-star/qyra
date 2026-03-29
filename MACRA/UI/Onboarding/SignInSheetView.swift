import SwiftUI

struct SignInSheetView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .blur(radius: 4)
                .onTapGesture {
                    viewModel.showSignInSheet = false
                }

            // Sheet
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 2)
                        .fill(OnboardingTheme.progressEmpty)
                        .frame(width: 36, height: 4)
                        .padding(.top, DesignTokens.Layout.itemGap)

                    // Header
                    HStack {
                        Text("Sign In")
                            .font(QyraFont.bold(24))
                            .foregroundStyle(OnboardingTheme.textPrimary)

                        Spacer()

                        // Close button
                        Button {
                            viewModel.showSignInSheet = false
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(OnboardingTheme.backgroundSecondary)
                                    .frame(width: 32, height: 32)

                                Image(systemName: "xmark")
                                    .font(QyraFont.semibold(12))
                                    .foregroundStyle(OnboardingTheme.textPrimary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, OnboardingTheme.screenPadding)
                    .padding(.top, DesignTokens.Layout.screenMargin)

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
                            // Apple sign-in action
                        }

                        // Sign in with Google
                        authButton(
                            icon: {
                                Text("G")
                                    .font(QyraFont.medium(24))
                                    .foregroundStyle(OnboardingTheme.textPrimary)
                            },
                            label: "Sign in with Google",
                            labelColor: OnboardingTheme.textPrimary,
                            background: OnboardingTheme.background,
                            borderColor: OnboardingTheme.divider
                        ) {
                            // Google sign-in action
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
                            background: OnboardingTheme.background,
                            borderColor: OnboardingTheme.divider
                        ) {
                            // Email sign-in action
                        }
                    }
                    .padding(.horizontal, OnboardingTheme.screenPadding)
                    .padding(.top, 28)

                    // Footer
                    termsFooter
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                        .padding(.top, DesignTokens.Layout.screenMargin)
                        .padding(.bottom, DesignTokens.Layout.sectionGap)
                }
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 24,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 24
                    )
                    .fill(OnboardingTheme.background)
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .transition(.opacity)
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

    // MARK: - Terms Footer

    private var termsFooter: some View {
        Text(termsAttributedString)
            .font(QyraFont.regular(13))
            .foregroundStyle(OnboardingTheme.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(13 * 0.4) // ~1.4 line height
            .frame(maxWidth: .infinity)
    }

    private var termsAttributedString: AttributedString {
        var full = AttributedString("By continuing you agree to Qyra's ")
        full.foregroundColor = OnboardingTheme.textSecondary

        var terms = AttributedString("Terms of Service")
        terms.foregroundColor = OnboardingTheme.textPrimary
        terms.underlineStyle = .single

        var and = AttributedString(" and ")
        and.foregroundColor = OnboardingTheme.textSecondary

        var privacy = AttributedString("Privacy Policy")
        privacy.foregroundColor = OnboardingTheme.textPrimary
        privacy.underlineStyle = .single

        return full + terms + and + privacy
    }
}

#Preview {
    ZStack {
        Color.white.ignoresSafeArea()
        SignInSheetView(viewModel: .preview)
    }
}
