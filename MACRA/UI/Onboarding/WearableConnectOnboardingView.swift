import SwiftUI

struct WearableConnectOnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel
    @State private var wearableService = WearableService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content — device list with bottom clearance
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Spacer().frame(height: DesignTokens.Layout.screenMargin)

                    WearableConnectionView(isOnboarding: true)
                }
                .padding(.bottom, 120) // Clear the fixed bottom buttons
            }

            // Fixed bottom buttons — outside ScrollView
            VStack(spacing: DesignTokens.Spacing.sm) {
                OnboardingContinueButton(label: "Continue", isEnabled: true) {
                    viewModel.advance()
                }

                if wearableService.connectedProviders.isEmpty {
                    Button {
                        DesignTokens.Haptics.light()
                        viewModel.advance()
                    } label: {
                        Text("Skip for now")
                            .font(QyraFont.medium(15))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .padding(.bottom, DesignTokens.Spacing.md)
                }
            }
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .background(OnboardingTheme.background)
        .onAppear {
            if viewModel.isHealthKitAuthorized {
                Task { await wearableService.connect(.appleWatch) }
            }
        }
    }
}

#Preview {
    WearableConnectOnboardingView(viewModel: .preview)
}
