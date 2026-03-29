import SwiftUI

struct CaloriesBurnedView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    OnboardingTitle(text: "Add calories burned back to your daily goal?")
                        .padding(.top, DesignTokens.Spacing.lg)

                    // Illustration with floating card
                    exerciseIllustration
                        .padding(.top, DesignTokens.Spacing.xl)
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                }
            }

            Spacer()

            // Bottom buttons: No / Yes
            HStack(spacing: DesignTokens.Layout.itemGap) {
                choiceButton(label: "No", value: false)
                choiceButton(label: "Yes", value: true)
            }
            .padding(.horizontal, OnboardingTheme.screenPadding)
            .padding(.bottom, DesignTokens.Layout.sectionGap)
            .padding(.top, DesignTokens.Layout.itemGap)
        }
    }

    // MARK: - Exercise Illustration

    private var exerciseIllustration: some View {
        ZStack(alignment: .bottomLeading) {
            // Large background with hero running illustration
            RoundedRectangle(cornerRadius: DesignTokens.Layout.cardCornerRadius)
                .fill(OnboardingTheme.backgroundSecondary)
                .frame(height: 320)
                .overlay {
                    ZStack {
                        Circle()
                            .fill(OnboardingTheme.backgroundTertiary.opacity(0.5))
                            .frame(width: 200, height: 200)
                        Image(systemName: "figure.run.circle.fill")
                            .font(.system(size: 120))
                            .foregroundStyle(OnboardingTheme.textPrimary, OnboardingTheme.backgroundTertiary)
                    }
                }

            // Floating info card
            VStack(alignment: .leading, spacing: DesignTokens.Layout.tightGap) {
                Text("Today's Goal")
                    .font(QyraFont.medium(13))
                    .foregroundStyle(OnboardingTheme.textSecondary)

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(QyraFont.regular(20))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                    Text("500 Cals")
                        .font(QyraFont.bold(24))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                }

                HStack(spacing: 6) {
                    Image(systemName: "shoe.fill")
                        .font(QyraFont.regular(14))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                    Text("Running")
                        .font(QyraFont.medium(14))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                }

                Text("+100 cals")
                    .font(QyraFont.semibold(14))
                    .foregroundStyle(OnboardingTheme.textPrimary)
            }
            .padding(DesignTokens.Layout.cardInternalPadding)
            .background(
                RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius)
                    .fill(OnboardingTheme.background)
                    .shadow(
                        color: OnboardingTheme.cardShadow.color,
                        radius: OnboardingTheme.cardShadow.radius,
                        y: OnboardingTheme.cardShadow.y
                    )
            )
            .padding(DesignTokens.Layout.screenMargin)
        }
    }

    // MARK: - Choice Button

    private func choiceButton(label: String, value: Bool) -> some View {
        Button {
            DesignTokens.Haptics.medium()
            viewModel.addCaloriesBurnedBack = value
            viewModel.advance()
        } label: {
            Text(label)
                .font(QyraFont.semibold(17))
                .foregroundStyle(OnboardingTheme.selectedCardText)
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingTheme.buttonHeight)
                .background(OnboardingTheme.selectedCardBg)
                .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CaloriesBurnedView(viewModel: .preview)
}
