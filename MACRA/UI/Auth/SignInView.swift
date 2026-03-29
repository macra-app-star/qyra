import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                Text("Sign In")
                    .font(QyraFont.semibold(20))
                    .foregroundStyle(DesignTokens.Colors.ink)

                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(QyraFont.semibold(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(DesignTokens.Colors.neutral90)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Divider
            Rectangle()
                .fill(OnboardingTheme.divider)
                .frame(height: 1)

            // Auth buttons
            VStack(spacing: 12) {
                // Sign in with Apple
                Button {
                    handleAppleSignIn()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "apple.logo")
                            .font(QyraFont.regular(18))
                        Text("Sign in with Apple")
                            .font(QyraFont.semibold(17))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .background(Color.black)
                    .clipShape(Capsule())
                }

            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Spacer(minLength: 16)

            // Error message
            if let error = AuthService.shared.errorMessage {
                Text(error)
                    .font(QyraFont.regular(13))
                    .foregroundStyle(DesignTokens.Colors.destructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            #if DEBUG
            Button {
                appState.skipToReady()
                dismiss()
            } label: {
                Text("Skip (Dev)")
                    .font(QyraFont.medium(13))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(.bottom, 4)
            #endif

            // Terms
            (Text("By continuing you agree to Qyra's")
                .foregroundStyle(OnboardingTheme.textSecondary)
            + Text("Terms and Conditions")
                .foregroundStyle(OnboardingTheme.textPrimary)
                .underline()
            + Text(" and ")
                .foregroundStyle(OnboardingTheme.textSecondary)
            + Text("Privacy Policy")
                .foregroundStyle(OnboardingTheme.textPrimary)
                .underline())
                .font(QyraFont.regular(13))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)
        }
        .background(OnboardingTheme.background)
    }

    // MARK: - Auth

    private func handleAppleSignIn() {
        Task {
            let success = await AuthService.shared.signIn()
            if success {
                await appState.evaluateGate()
            }
        }
    }
}

#Preview {
    SignInView()
        .environment(AppState())
}
