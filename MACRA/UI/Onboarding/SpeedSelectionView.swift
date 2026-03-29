import SwiftUI

struct SpeedSelectionView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var sliderPosition: CGFloat = 1 // 0=Slow, 1=Recommended, 2=Fast

    var body: some View {
        VStack(spacing: 0) {
            // Title
            OnboardingTitle(text: "How fast do you want to reach your goal?")
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Center content
            VStack(spacing: 0) {
                // Speed step label
                Text(viewModel.speedStepTitle)
                    .font(QyraFont.regular(14))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                // Weekly rate value
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Layout.microGap) {
                    Text(String(format: "%.1f", viewModel.weeklyWeightChange))
                        .font(QyraFont.bold(40))
                        .tracking(-1.5)
                        .foregroundStyle(OnboardingTheme.textPrimary)

                    Text("lbs")
                        .font(QyraFont.medium(22))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                }
                .padding(.top, DesignTokens.Layout.tightGap)

                // Speed icons row
                HStack(spacing: 40) {
                    ForEach(WeightSpeed.allCases) { speed in
                        speedOption(speed)
                    }
                }
                .padding(.top, DesignTokens.Spacing.lg)

                // Custom slider
                speedSlider
                    .padding(.top, DesignTokens.Layout.tightGap)
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                // Info card
                infoCard
                    .padding(.top, DesignTokens.Layout.screenMargin)
                    .padding(.horizontal, OnboardingTheme.screenPadding)
            }

            Spacer()

            // Continue button
            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
        .onAppear {
            sliderPosition = CGFloat(viewModel.speedSelection.rawValue)
        }
    }

    // MARK: - Speed Option

    private func speedOption(_ speed: WeightSpeed) -> some View {
        let isSelected = viewModel.speedSelection == speed

        return Button {
            DesignTokens.Haptics.selection()
            withAnimation(OnboardingTheme.defaultSpring) {
                viewModel.speedSelection = speed
                sliderPosition = CGFloat(speed.rawValue)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: speed.sfSymbol)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? OnboardingTheme.selectedCardBg : OnboardingTheme.textSecondary)
                    .opacity(isSelected ? 1.0 : 0.5)

                Text(speed.label)
                    .font(isSelected ? QyraFont.bold(13) : QyraFont.regular(13))
                    .foregroundStyle(isSelected ? OnboardingTheme.selectedCardBg : OnboardingTheme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Slider

    private var speedSlider: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let thumbSize: CGFloat = 28
            let usableWidth = trackWidth - thumbSize
            let stepWidth = usableWidth / 2
            let thumbX = thumbSize / 2 + sliderPosition * stepWidth
            let fillWidth = thumbX

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: 2)
                    .fill(OnboardingTheme.progressEmpty)
                    .frame(height: 4)

                // Filled track
                RoundedRectangle(cornerRadius: 2)
                    .fill(OnboardingTheme.selectedCardBg)
                    .frame(width: fillWidth, height: 4)

                // Thumb
                Circle()
                    .fill(OnboardingTheme.background)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(Circle().strokeBorder(OnboardingTheme.divider, lineWidth: 1))
                    .offset(x: thumbX - thumbSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let rawPosition = (value.location.x - thumbSize / 2) / stepWidth
                                let clamped = min(max(rawPosition, 0), 2)
                                sliderPosition = clamped
                            }
                            .onEnded { _ in
                                let snapped = (sliderPosition + 0.5).rounded(.down)
                                let snappedInt = Int(min(max(snapped, 0), 2))
                                withAnimation(OnboardingTheme.defaultSpring) {
                                    sliderPosition = CGFloat(snappedInt)
                                }
                                if let speed = WeightSpeed(rawValue: snappedInt) {
                                    DesignTokens.Haptics.light()
                                    viewModel.speedSelection = speed
                                }
                            }
                    )
            }
            .frame(height: thumbSize)
        }
        .frame(height: 28)
    }

    // MARK: - Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Layout.tightGap) {
            (
                Text("You will reach your goal in ")
                    .font(QyraFont.regular(15))
                    .foregroundStyle(OnboardingTheme.textPrimary)
                +
                Text(viewModel.timelineLabel)
                    .font(QyraFont.bold(15))
                    .foregroundStyle(OnboardingTheme.accent)
            )

            Text(viewModel.speedDescriptionForGoal)
                .font(QyraFont.regular(13))
                .foregroundStyle(OnboardingTheme.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("Daily calorie goal: \(viewModel.calculatedCalories) cal")
                .font(QyraFont.regular(13))
                .foregroundStyle(OnboardingTheme.textSecondary)
        }
        .padding(OnboardingTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(OnboardingTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
    }
}

#Preview {
    SpeedSelectionView(viewModel: .preview)
}
