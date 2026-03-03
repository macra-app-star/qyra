import SwiftUI

struct AppGateView: View {
    @State var appState = AppState()

    var body: some View {
        Group {
            switch appState.gateStatus {
            case .loading:
                LaunchScreenView()
            case .needsAuth:
                // Phase 4: SignInView()
                PlaceholderView(title: "Sign In", icon: "person.circle")
            case .needsSubscription:
                PaywallView()
            case .needsOnboarding:
                // Phase 3: OnboardingFlowView()
                PlaceholderView(title: "Onboarding", icon: "arrow.right.circle")
            case .ready:
                MainTabView()
            }
        }
        .animation(DesignTokens.Anim.standard, value: appState.gateStatus)
        .environment(appState)
        .task {
            await appState.evaluateGate()
        }
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("MACRA")
                    .font(DesignTokens.Typography.largeTitle)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                ProgressView()
                    .tint(DesignTokens.Colors.textSecondary)
            }
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let icon: String

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 48))
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
