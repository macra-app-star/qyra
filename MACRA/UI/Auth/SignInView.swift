import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(AppState.self) private var appState

    // MARK: - Animation State

    @State private var logoVisible = false
    @State private var taglineVisible = false
    @State private var featuresVisible = false
    @State private var buttonsVisible = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // MARK: - Logo + Branding

                VStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .scaleEffect(logoVisible ? 1 : 0.5)
                        .opacity(logoVisible ? 1 : 0)

                    Text("MACRA")
                        .font(DesignTokens.Typography.largeTitle)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .opacity(logoVisible ? 1 : 0)

                    Text("AI-Powered Macro Tracking")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .opacity(taglineVisible ? 1 : 0)
                        .offset(y: taglineVisible ? 0 : 8)
                }

                Spacer()
                    .frame(height: DesignTokens.Spacing.xxl)

                // MARK: - Feature Highlights

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    featureHighlight(
                        icon: "camera.fill",
                        title: "Snap & Track",
                        subtitle: "Photo-powered meal logging"
                    )
                    featureHighlight(
                        icon: "mic.fill",
                        title: "Voice Log",
                        subtitle: "Describe meals naturally"
                    )
                    featureHighlight(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Smart Insights",
                        subtitle: "AI-driven nutrition coaching"
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .opacity(featuresVisible ? 1 : 0)
                .offset(y: featuresVisible ? 0 : 16)

                Spacer()

                // MARK: - Sign In Buttons

                VStack(spacing: DesignTokens.Spacing.md) {

                    // Error message
                    if let error = AuthService.shared.errorMessage {
                        Text(error)
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.destructive)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }

                    #if DEBUG
                    MonochromeButton("Skip Sign In (Dev)", icon: "forward.fill", style: .secondary) {
                        appState.skipToReady()
                    }
                    #endif

                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                    .overlay {
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
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.xxl)
                .opacity(buttonsVisible ? 1 : 0)
                .offset(y: buttonsVisible ? 0 : 20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                taglineVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) {
                featuresVisible = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
                buttonsVisible = true
            }
        }
    }

    // MARK: - Feature Highlight

    private func featureHighlight(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .frame(width: 36, height: 36)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(subtitle)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
    }
}
