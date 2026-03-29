import SwiftUI

struct AllDoneView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showIllustration = false
    @State private var showContent = false

    // Confetti dot positions (angle, distance)
    private let confettiPositions: [(CGFloat, CGFloat)] = [
        (30, 120), (75, 115), (120, 125), (165, 118),
        (210, 122), (255, 116), (300, 128), (345, 120),
        (50, 105), (200, 108)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                // Illustration (similar to TrustView)
                ZStack {
                    // Outer ring
                    Circle()
                        .fill(OnboardingTheme.accent.opacity(0.3))
                        .frame(width: 240, height: 240)

                    // Inner ring
                    Circle()
                        .fill(OnboardingTheme.accent.opacity(0.5))
                        .frame(width: 180, height: 180)

                    // Hand with heart icon
                    VStack(spacing: 0) {
                        Image(systemName: "heart.fill")
                            .font(QyraFont.regular(20))
                            .foregroundStyle(OnboardingTheme.accent)
                            .offset(y: 8)

                        Image(systemName: "hand.point.up")
                            .font(QyraFont.regular(80))
                            .foregroundStyle(OnboardingTheme.textPrimary)
                    }

                    // Confetti dots
                    ForEach(0..<confettiPositions.count, id: \.self) { index in
                        let position = confettiPositions[index]
                        let angle = Angle(degrees: Double(position.0))
                        let distance = position.1

                        Circle()
                            .fill(OnboardingTheme.textPrimary)
                            .frame(width: CGFloat.random(in: 4...6), height: CGFloat.random(in: 4...6))
                            .offset(
                                x: cos(angle.radians) * distance,
                                y: sin(angle.radians) * distance
                            )
                    }
                }
                .frame(width: 280, height: 280)
                .scaleEffect(showIllustration ? 1 : 0.8)
                .opacity(showIllustration ? 1 : 0)

                if showContent {
                    VStack(spacing: DesignTokens.Layout.itemGap) {
                        // "All done!" badge
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(QyraFont.regular(20))
                                .foregroundStyle(OnboardingTheme.accent)
                            Text("All done!")
                                .font(QyraFont.semibold(16))
                                .foregroundStyle(OnboardingTheme.textPrimary)
                        }

                        // Main title
                        Text("Time to generate\nyour custom plan!")
                            .font(OnboardingTheme.titleFont)
                            .tracking(OnboardingTheme.titleTracking)
                            .foregroundStyle(OnboardingTheme.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            OnboardingContinueButton(label: "Continue") {
                DesignTokens.Haptics.success()
                viewModel.advance()
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(OnboardingTheme.defaultSpring) {
                showIllustration = true
            }

            try? await Task.sleep(for: .milliseconds(400))
            withAnimation(.easeOut(duration: 0.4)) {
                showContent = true
            }
        }
    }
}

#Preview {
    AllDoneView(viewModel: .preview)
}
