import SwiftUI

struct WeightTransitionView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var isGaining: Bool {
        viewModel.goalType == .bulk
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "You have great potential to crush your goal")
                .padding(.top, DesignTokens.Spacing.lg)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Chart card
                    weightTransitionCard
                        .padding(.horizontal, OnboardingTheme.screenPadding)
                        .padding(.top, DesignTokens.Spacing.lg)
                }
                .padding(.bottom, DesignTokens.Layout.cardGap)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
    }

    // MARK: - Weight Transition Card

    private var weightTransitionCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Layout.cardGap) {
            // Header
            Text("Your weight transition")
                .font(QyraFont.semibold(17))
                .foregroundStyle(OnboardingTheme.textPrimary)

            // Chart
            GeometryReader { geo in
                let width = geo.size.width
                let height = geo.size.height

                ZStack {
                    // Dotted baseline
                    dottedBaseline(width: width, height: height)

                    // Shaded fill under curve
                    curveFill(width: width, height: height)

                    // Curve line
                    curveLine(width: width, height: height)

                    // Data point dots
                    dataPointDots(width: width, height: height)

                    // Trophy icon at end
                    trophyIcon(width: width, height: height)
                }
            }
            .frame(height: 160)

            // X-axis labels
            HStack {
                Text("3 Days")
                    .font(QyraFont.regular(13))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                Spacer()
                Text("7 Days")
                    .font(QyraFont.regular(13))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                Spacer()
                Text("30 Days")
                    .font(QyraFont.regular(13))
                    .foregroundStyle(OnboardingTheme.textSecondary)
            }

            // Description
            Text(descriptionText)
                .font(QyraFont.regular(13))
                .foregroundStyle(OnboardingTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: .infinity)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(OnboardingTheme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.cardCornerRadius))
    }

    // MARK: - Description text

    private var descriptionText: String {
        if isGaining {
            return "Based on Qyra's historical data, weight gain is usually delayed at first, but after 7 days, you can reach your goal quickly!"
        } else {
            return "Based on Qyra's historical data, weight loss is usually delayed at first, but after 7 days, you can reach your goal quickly!"
        }
    }

    // MARK: - Chart Y positions

    private func startY(_ height: CGFloat) -> CGFloat {
        isGaining ? height * 0.75 : height * 0.25
    }

    private func threeY(_ height: CGFloat) -> CGFloat {
        isGaining ? height * 0.65 : height * 0.35
    }

    private func sevenY(_ height: CGFloat) -> CGFloat {
        isGaining ? height * 0.45 : height * 0.55
    }

    private func thirtyY(_ height: CGFloat) -> CGFloat {
        isGaining ? height * 0.15 : height * 0.85
    }

    // MARK: - Chart Components

    private func dottedBaseline(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let y = startY(height)
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(OnboardingTheme.textSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    private func curveLine(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let p0 = CGPoint(x: 0, y: startY(height))
            let p1 = CGPoint(x: width * 0.25, y: threeY(height))
            let p2 = CGPoint(x: width * 0.50, y: sevenY(height))
            let p3 = CGPoint(x: width, y: thirtyY(height))

            path.move(to: p0)
            path.addCurve(
                to: p1,
                control1: CGPoint(x: width * 0.10, y: startY(height)),
                control2: CGPoint(x: width * 0.18, y: threeY(height))
            )
            path.addCurve(
                to: p2,
                control1: CGPoint(x: width * 0.32, y: threeY(height)),
                control2: CGPoint(x: width * 0.42, y: sevenY(height))
            )
            path.addCurve(
                to: p3,
                control1: CGPoint(x: width * 0.60, y: sevenY(height)),
                control2: CGPoint(x: width * 0.85, y: thirtyY(height))
            )
        }
        .stroke(OnboardingTheme.textPrimary, lineWidth: 2.5)
    }

    private func curveFill(width: CGFloat, height: CGFloat) -> some View {
        Path { path in
            let p0 = CGPoint(x: 0, y: startY(height))
            let p1 = CGPoint(x: width * 0.25, y: threeY(height))
            let p2 = CGPoint(x: width * 0.50, y: sevenY(height))
            let p3 = CGPoint(x: width, y: thirtyY(height))

            path.move(to: p0)
            path.addCurve(
                to: p1,
                control1: CGPoint(x: width * 0.10, y: startY(height)),
                control2: CGPoint(x: width * 0.18, y: threeY(height))
            )
            path.addCurve(
                to: p2,
                control1: CGPoint(x: width * 0.32, y: threeY(height)),
                control2: CGPoint(x: width * 0.42, y: sevenY(height))
            )
            path.addCurve(
                to: p3,
                control1: CGPoint(x: width * 0.60, y: sevenY(height)),
                control2: CGPoint(x: width * 0.85, y: thirtyY(height))
            )
            path.addLine(to: CGPoint(x: width, y: startY(height)))
            path.addLine(to: CGPoint(x: 0, y: startY(height)))
            path.closeSubpath()
        }
        .fill(OnboardingTheme.accent.opacity(0.08))
    }

    private func dataPointDots(width: CGFloat, height: CGFloat) -> some View {
        let points: [(CGFloat, CGFloat)] = [
            (0, startY(height)),
            (width * 0.25, threeY(height)),
            (width * 0.50, sevenY(height)),
        ]

        return ForEach(0..<points.count, id: \.self) { index in
            Circle()
                .fill(OnboardingTheme.background)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(OnboardingTheme.textPrimary, lineWidth: 2)
                )
                .position(x: points[index].0, y: points[index].1)
        }
    }

    private func trophyIcon(width: CGFloat, height: CGFloat) -> some View {
        Image(systemName: "trophy.fill")
            .font(QyraFont.regular(16))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(OnboardingTheme.accent)
            .clipShape(Circle())
            .position(x: width, y: thirtyY(height))
    }
}

#Preview {
    WeightTransitionView(viewModel: .preview)
}
