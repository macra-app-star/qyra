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
                SignInView()
            case .needsSubscription:
                PaywallView()
            case .needsOnboarding:
                OnboardingView {
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
