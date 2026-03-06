import SwiftUI

struct LoadingOverlay: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.border, lineWidth: 3)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(DesignTokens.Colors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
            }

            Text(message)
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text("This may take a moment")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.background.opacity(0.9))
        .onAppear { isAnimating = true }
    }
}
