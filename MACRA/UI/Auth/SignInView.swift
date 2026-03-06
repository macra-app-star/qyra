import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.xxl) {
                Spacer()

                // Logo + branding
                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("MACRA")
                        .font(DesignTokens.Typography.largeTitle)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("AI-Powered Macro Tracking")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer()

                // Sign in button
                VStack(spacing: DesignTokens.Spacing.md) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        // Handled via AuthService delegate
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                    .overlay {
                        // Invisible button that actually triggers our auth flow
                        Button {
                            Task {
                                let success = await AuthService.shared.signIn()
                                if success {
                                    await appState.evaluateGate()
                                }
                            }
                        } label: {
                            Color.clear
                        }
                    }

                    Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .multilineTextAlignment(.center)

                    if let error = AuthService.shared.errorMessage {
                        Text(error)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.destructive)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
        }
    }
}
