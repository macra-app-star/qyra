import SwiftUI

struct GainComparisonView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Reach your goals faster with Qyra")
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Comparison card
            comparisonCard
                .padding(.horizontal, OnboardingTheme.screenPadding)

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }

    // MARK: - Comparison Card

    private var comparisonCard: some View {
        VStack(spacing: 0) {
            // Bar chart
            HStack(alignment: .bottom, spacing: DesignTokens.Layout.cardGap) {
                // "Without Qyra" bar
                VStack(spacing: DesignTokens.Layout.itemGap) {
                    Text("Without\nQyra")
                        .font(QyraFont.bold(15))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(OnboardingTheme.background)
                        .frame(height: 140)
                        .overlay(alignment: .bottom) {
                            Text("Slower")
                                .font(QyraFont.bold(14))
                                .foregroundStyle(OnboardingTheme.textSecondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(OnboardingTheme.backgroundTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.bottom, 12)
                        }
                }
                .frame(maxWidth: .infinity)

                // "With Qyra" bar
                VStack(spacing: DesignTokens.Layout.itemGap) {
                    Text("With\nQyra")
                        .font(QyraFont.bold(15))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    RoundedRectangle(cornerRadius: 14)
                        .fill(OnboardingTheme.textPrimary)
                        .frame(height: 220)
                        .overlay(alignment: .bottom) {
                            Text("Faster")
                                .font(QyraFont.bold(14))
                                .foregroundStyle(OnboardingTheme.background)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(OnboardingTheme.textPrimary.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .padding(.bottom, 12)
                        }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.xl)

            // Tagline
            Text("Track smarter. Stay consistent.")
                .font(QyraFont.regular(14))
                .foregroundStyle(OnboardingTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, DesignTokens.Spacing.lg)
                .padding(.bottom, DesignTokens.Spacing.xl)
                .padding(.horizontal, OnboardingTheme.screenPadding)
        }
        .background(OnboardingTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
    }
}

#Preview {
    GainComparisonView(viewModel: .preview)
}
