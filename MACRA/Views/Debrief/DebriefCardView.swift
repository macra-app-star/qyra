import SwiftUI

struct DebriefCardView: View {
    let card: DebriefCard
    let isLastCard: Bool
    var onShare: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Metric
            if let metric = card.metric {
                ZStack {
                    // Accent glow behind metric
                    Circle()
                        .fill(card.accentColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .blur(radius: 40)

                    Text(metric)
                        .font(DesignTokens.Typography.numeric(56))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
                .padding(.bottom, DesignTokens.Spacing.lg)
            }

            // Title
            Text(card.title)
                .font(DesignTokens.Typography.semibold(24))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, DesignTokens.Spacing.sm)

            // Body
            Text(card.body)
                .font(DesignTokens.Typography.bodyFont(16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, DesignTokens.Spacing.xl)
                .padding(.bottom, DesignTokens.Spacing.lg)

            // Trend indicator
            if let trend = card.trend {
                HStack(spacing: 6) {
                    Image(systemName: trend.iconName)
                        .font(DesignTokens.Typography.icon(14))
                    Text(trendLabel(trend))
                        .font(DesignTokens.Typography.medium(14))
                }
                .foregroundColor(trendColor(trend))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(trendColor(trend).opacity(0.15))
                .clipShape(Capsule())
                .padding(.bottom, DesignTokens.Spacing.lg)
            }

            Spacer()

            // Share button on last card
            if isLastCard {
                Button(action: {
                    onShare?()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(DesignTokens.Typography.icon(16))
                        Text("Share to Stories")
                            .font(DesignTokens.Typography.semibold(16))
                    }
                    .foregroundColor(Color(uiColor: UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func trendLabel(_ trend: Trend) -> String {
        switch trend {
        case .up: return "Improving"
        case .down: return "Needs work"
        case .flat: return "Steady"
        }
    }

    private func trendColor(_ trend: Trend) -> Color {
        switch trend {
        case .up: return DesignTokens.Colors.healthGreen
        case .down: return DesignTokens.Colors.destructive
        case .flat: return DesignTokens.Colors.accent
        }
    }
}
