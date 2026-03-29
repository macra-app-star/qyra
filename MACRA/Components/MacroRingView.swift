import SwiftUI

struct MacroRingView: View {
    let progress: Double
    var ringColor: Color = DesignTokens.Colors.ringCalories
    var trackColor: Color = Color(.systemGray5)
    var size: CGFloat = 80
    var lineWidth: CGFloat = 10
    var centerContent: (() -> AnyView)? = nil

    /// Allows overfill up to 150% for Apple Activity Ring overlap effect
    private var displayProgress: Double {
        min(max(progress, 0), 1.5)
    }

    var body: some View {
        ZStack {
            // Track — faint background ring
            Circle()
                .stroke(
                    trackColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            // Progress arc — solid color, clockwise from 12 o'clock
            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: displayProgress)

            // Optional center content
            if let content = centerContent {
                content()
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress ring, \(Int(min(max(progress, 0), 1.0) * 100)) percent")
    }
}

// MARK: - Convenience initializer with ViewBuilder

extension MacroRingView {
    init<Content: View>(
        progress: Double,
        ringColor: Color = DesignTokens.Colors.ringCalories,
        trackColor: Color = Color(.systemGray5),
        size: CGFloat = 80,
        lineWidth: CGFloat = 10,
        @ViewBuilder center: @escaping () -> Content
    ) {
        self.progress = progress
        self.ringColor = ringColor
        self.trackColor = trackColor
        self.size = size
        self.lineWidth = lineWidth
        self.centerContent = { AnyView(center()) }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        // Calorie ring — large, thick
        MacroRingView(
            progress: 0.72,
            ringColor: DesignTokens.Colors.ringCalories,
            size: 140,
            lineWidth: 20
        ) {
            VStack(spacing: 2) {
                Text("1440")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text("of 2000")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }

        // Macro ring — smaller, thinner
        HStack(spacing: DesignTokens.Spacing.md) {
            MacroRingView(
                progress: 0.63,
                ringColor: DesignTokens.Colors.ringProtein,
                size: 56,
                lineWidth: 10
            ) {
                Text("95")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            MacroRingView(
                progress: 0.45,
                ringColor: DesignTokens.Colors.ringCarbs,
                size: 56,
                lineWidth: 10
            ) {
                Text("160")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            // Overfill demo
            MacroRingView(
                progress: 1.3,
                ringColor: DesignTokens.Colors.ringFat,
                size: 56,
                lineWidth: 10
            ) {
                Text("85")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
        }
    }
    .padding(DesignTokens.Spacing.lg)
    .background(DesignTokens.Colors.background)
}
