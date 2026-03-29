import SwiftUI

struct AppGateView: View {
    @Environment(\.modelContext) private var modelContext
    @State var appState = AppState()

    var body: some View {
        Group {
            switch appState.gateStatus {
            case .loading:
                LaunchScreenView()
            case .needsAuth:
                LandingView()
            case .needsSubscription:
                PaywallView()
            case .needsOnboarding:
                OnboardingContainerView {
                    Task { await appState.completeOnboarding() }
                }
            case .ready:
                MainTabView()
            }
        }
        .animation(DesignTokens.Anim.standard, value: appState.gateStatus)
        .environment(appState)
        .task {
            appState.modelContainer = modelContext.container
            appState.subscriptionService.startListening()
            await appState.evaluateGate()
        }
    }
}

// MARK: - Splash Screen

struct LaunchScreenView: View {
    @State private var visible = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.neutral100
                .ignoresSafeArea()

            (Text("Qyra.")
                .font(QyraFont.bold(38))
            + Text("®")
                .font(QyraFont.regular(16))
                .baselineOffset(16))
                .foregroundStyle(DesignTokens.Colors.ink)
                .opacity(visible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                visible = true
            }
        }
    }
}

// MARK: - Placeholder

struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(DesignTokens.Typography.icon(48))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text(title)
                    .font(DesignTokens.Typography.title)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Coming soon")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
    }
}

#Preview {
    AppGateView()
}
