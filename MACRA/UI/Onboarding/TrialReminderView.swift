import SwiftUI

struct TrialReminderView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                // Bell icon
                ZStack {
                    Circle()
                        .fill(OnboardingTheme.accent.opacity(0.12))
                        .frame(width: 100, height: 100)

                    Image(systemName: "bell.badge")
                        .font(QyraFont.medium(40))
                        .foregroundStyle(OnboardingTheme.accent)
                }

                VStack(spacing: DesignTokens.Layout.itemGap) {
                    Text("We'll remind you before your trial ends")
                        .font(OnboardingTheme.titleFont)
                        .tracking(OnboardingTheme.titleTracking)
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("You'll get a notification before you're charged. Cancel anytime with no questions asked.")
                        .font(OnboardingTheme.subtitleFont)
                        .foregroundStyle(OnboardingTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignTokens.Layout.itemGap)
                }

                // Timeline graphic
                trialTimeline
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            OnboardingContinueButton(label: "Got it") {
                viewModel.advance()
            }
        }
    }

    // MARK: - Trial Timeline

    private var trialTimeline: some View {
        HStack(spacing: 0) {
            // Start
            VStack(spacing: 6) {
                Circle()
                    .fill(OnboardingTheme.accentGreen)
                    .frame(width: 12, height: 12)

                Text("Today")
                    .font(QyraFont.medium(12))
                    .foregroundStyle(OnboardingTheme.textSecondary)
            }

            // Line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [OnboardingTheme.accentGreen, OnboardingTheme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .padding(.bottom, DesignTokens.Layout.screenMargin)

            // Reminder
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(OnboardingTheme.accent)
                        .frame(width: 12, height: 12)

                    Image(systemName: "bell.fill")
                        .font(QyraFont.regular(6))
                        .foregroundStyle(.white)
                }

                Text("Reminder")
                    .font(QyraFont.medium(12))
                    .foregroundStyle(OnboardingTheme.textSecondary)
            }

            // Line
            Rectangle()
                .fill(OnboardingTheme.progressEmpty)
                .frame(height: 2)
                .padding(.bottom, DesignTokens.Layout.screenMargin)

            // End
            VStack(spacing: 6) {
                Circle()
                    .fill(OnboardingTheme.progressEmpty)
                    .frame(width: 12, height: 12)

                Text("Day 7")
                    .font(QyraFont.medium(12))
                    .foregroundStyle(OnboardingTheme.textTertiary)
            }
        }
        .padding(.horizontal, DesignTokens.Layout.tightGap)
        .padding(.top, DesignTokens.Layout.tightGap)
    }
}

#Preview {
    TrialReminderView(viewModel: .preview)
}
