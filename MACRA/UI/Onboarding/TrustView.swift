import SwiftUI

struct TrustView: View {
    @Bindable var viewModel: OnboardingViewModel

    // Random confetti dot positions (angle in degrees, distance from center)
    private let confettiPositions: [(CGFloat, CGFloat)] = [
        (30, 110), (75, 105), (120, 115), (165, 108),
        (210, 112), (255, 106), (300, 118), (345, 110),
        (50, 95), (200, 98)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Illustration
                    illustrationSection
                        .padding(.top, DesignTokens.Layout.sectionGap)

                    // Title
                    OnboardingTitle(text: "Thank you for trusting us", alignment: .center)
                        .padding(.top, DesignTokens.Spacing.lg)

                    // Subtitle
                    OnboardingSubtitle(text: "Now let's personalize Qyra for you...", alignment: .center)

                    // Privacy card
                    privacyCard
                        .padding(.top, DesignTokens.Spacing.lg)
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                }
            }

            Spacer()

            // Continue button
            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }

    // MARK: - Illustration

    private var illustrationSection: some View {
        ZStack {
            // Large circular background
            Circle()
                .fill(OnboardingTheme.accent.opacity(0.15))
                .frame(width: 200, height: 200)

            // Hand wave icon
            Image(systemName: "hand.wave")
                .font(QyraFont.regular(100))
                .foregroundStyle(OnboardingTheme.textPrimary)

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
        .frame(width: 260, height: 260)
    }

    // MARK: - Privacy Card

    private var privacyCard: some View {
        VStack(spacing: DesignTokens.Layout.itemGap) {
            Image(systemName: "lock.shield")
                .font(QyraFont.regular(28))
                .foregroundStyle(OnboardingTheme.accent)

            Text("Your privacy and security matter to us.")
                .font(QyraFont.semibold(16))
                .foregroundStyle(OnboardingTheme.textPrimary)
                .multilineTextAlignment(.center)

            Text("We promise to always keep your personal information private and secure.")
                .font(QyraFont.regular(14))
                .foregroundStyle(OnboardingTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(14 * 0.4)
        }
        .padding(OnboardingTheme.cardPadding)
        .frame(maxWidth: .infinity)
        .background(OnboardingTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
    }
}

#Preview {
    TrustView(viewModel: .preview)
}
