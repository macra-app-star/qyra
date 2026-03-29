import SwiftUI

struct HealthKitConnectView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Illustration
                    healthDataIllustration
                        .padding(.top, DesignTokens.Spacing.lg)

                    // Title
                    OnboardingTitle(text: "Connect to Apple Health")
                        .padding(.top, DesignTokens.Spacing.lg)

                    // Subtitle
                    OnboardingSubtitle(text: "Sync your daily activity between Qyra and the Health app to have the most thorough data.")
                }
            }

            Spacer()

            // Primary: Continue
            OnboardingContinueButton(label: "Continue", isEnabled: true) {
                Task {
                    _ = await HealthKitService.shared.requestAuthorization()
                    viewModel.advance()
                }
            }

            // Secondary: Skip
            Button {
                viewModel.advance()
            } label: {
                Text("Skip")
                    .font(QyraFont.semibold(17))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .padding(.bottom, DesignTokens.Spacing.lg)
            .padding(.top, -20)
        }
    }

    // MARK: - Health Data Illustration

    private var healthDataIllustration: some View {
        ZStack {
            // Large gray circle
            Circle()
                .fill(OnboardingTheme.backgroundSecondary)
                .frame(width: 250, height: 250)

            // Left labels
            VStack(alignment: .leading, spacing: DesignTokens.Layout.tightGap) {
                activityLabel("Walking")
                activityLabel("Running")
            }
            .offset(x: -60, y: -10)

            // Right labels
            VStack(alignment: .trailing, spacing: DesignTokens.Layout.tightGap) {
                activityLabel("Yoga")
                activityLabel("Sleep")
            }
            .offset(x: 60, y: -10)

            // Center checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(QyraFont.regular(28))
                .foregroundStyle(OnboardingTheme.textPrimary)

            // Top-right: Qyra wordmark badge
            Text("Qyra")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(OnboardingTheme.selectedCardText)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(OnboardingTheme.selectedCardBg, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .offset(x: 70, y: -80)

            // Bottom-left: Pink heart on light pink rounded square (Apple Health)
            RoundedRectangle(cornerRadius: 14)
                .fill(DesignTokens.Colors.error.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(QyraFont.regular(28))
                        .foregroundStyle(DesignTokens.Colors.error)
                )
                .offset(x: -70, y: 80)
        }
        .frame(height: 280)
    }

    private func activityLabel(_ text: String) -> some View {
        Text(text)
            .font(QyraFont.semibold(14))
            .foregroundStyle(OnboardingTheme.textPrimary)
    }
}

#Preview {
    HealthKitConnectView(viewModel: .preview)
}
