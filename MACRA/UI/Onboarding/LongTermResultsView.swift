import SwiftUI

struct LongTermResultsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Qyra creates long-term results")
                .padding(.top, DesignTokens.Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Chart card
                    weightChartCard
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                        .padding(.top, DesignTokens.Spacing.lg)

                    // Bottom stat text
                    Text("Consistency is the key to lasting results.")
                        .font(QyraFont.regular(13))
                        .foregroundStyle(OnboardingTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                        .padding(.top, 14)
                }
                .padding(.bottom, DesignTokens.Layout.cardGap)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }

    // MARK: - Weight Chart Card

    private var weightChartCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Layout.cardGap) {
            // Header
            Text("Your weight")
                .font(QyraFont.semibold(17))
                .foregroundStyle(OnboardingTheme.textPrimary)

            // Chart
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height

                ZStack {
                    // Traditional diet fill (not needed per spec, only Qyra line gets fill)

                    // Qyra line fill
                    macraLineFill(width: width, height: height)

                    // Traditional diet line (red)
                    traditionalDietLine(width: width, height: height)

                    // Qyra line (black)
                    macraLine(width: width, height: height)

                    // Start dot
                    startDot(width: width, height: height)

                    // End dots
                    macraEndDot(width: width, height: height)
                    traditionalEndDot(width: width, height: height)
                }
            }
            .frame(height: 140)

            // X-axis labels
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Month 1")
                        .font(QyraFont.regular(11))
                        .foregroundStyle(OnboardingTheme.textSecondary)
                    Text("Weight")
                        .font(QyraFont.medium(10))
                        .foregroundStyle(OnboardingTheme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, DesignTokens.Layout.microGap)
                        .background(OnboardingTheme.backgroundTertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                Spacer()
                Text("Month 6")
                    .font(QyraFont.regular(11))
                    .foregroundStyle(OnboardingTheme.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(OnboardingTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.cardCornerRadius))
    }

    // MARK: - Chart Paths

    private func macraLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let startX: CGFloat = 0
            let startY = height * 0.45
            let endX = width
            let endY = height * 0.85

            path.move(to: CGPoint(x: startX, y: startY))
            path.addCurve(
                to: CGPoint(x: endX, y: endY),
                control1: CGPoint(x: width * 0.35, y: height * 0.55),
                control2: CGPoint(x: width * 0.65, y: height * 0.82)
            )
        }
        .stroke(OnboardingTheme.textPrimary, lineWidth: 2.5)
    }

    private func macraLineFill(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let startX: CGFloat = 0
            let startY = height * 0.45
            let endX = width
            let endY = height * 0.85

            path.move(to: CGPoint(x: startX, y: startY))
            path.addCurve(
                to: CGPoint(x: endX, y: endY),
                control1: CGPoint(x: width * 0.35, y: height * 0.55),
                control2: CGPoint(x: width * 0.65, y: height * 0.82)
            )
            path.addLine(to: CGPoint(x: endX, y: height))
            path.addLine(to: CGPoint(x: startX, y: height))
            path.closeSubpath()
        }
        .fill(OnboardingTheme.textPrimary.opacity(0.06))
    }

    private func traditionalDietLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let startX: CGFloat = 0
            let startY = height * 0.45
            let endX = width
            let endY = height * 0.15

            path.move(to: CGPoint(x: startX, y: startY))
            path.addCurve(
                to: CGPoint(x: endX, y: endY),
                control1: CGPoint(x: width * 0.25, y: height * 0.52),
                control2: CGPoint(x: width * 0.55, y: height * 0.18)
            )
        }
        .stroke(OnboardingTheme.macroProtein.opacity(0.7), lineWidth: 2)
    }

    // MARK: - Dots

    private func startDot(width: CGFloat, height: CGFloat) -> some View {
        Circle()
            .fill(OnboardingTheme.background)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(OnboardingTheme.textPrimary, lineWidth: 2)
            )
            .position(x: 0, y: height * 0.45)
    }

    private func macraEndDot(width: CGFloat, height: CGFloat) -> some View {
        Circle()
            .fill(OnboardingTheme.background)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(OnboardingTheme.textPrimary, lineWidth: 2)
            )
            .position(x: width, y: height * 0.85)
    }

    private func traditionalEndDot(width: CGFloat, height: CGFloat) -> some View {
        Circle()
            .fill(OnboardingTheme.background)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(OnboardingTheme.macroProtein.opacity(0.7), lineWidth: 2)
            )
            .position(x: width, y: height * 0.15)
    }
}

#Preview {
    LongTermResultsView(
        viewModel: OnboardingViewModel.preview
    )
}
