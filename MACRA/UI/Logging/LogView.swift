import SwiftUI

struct LogView: View {
    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("Log a Meal")
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Scan a barcode, take a photo, or add manually")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    MonochromeButton("Scan Barcode", icon: "barcode.viewfinder", style: .primary) {}
                    MonochromeButton("Camera Scan", icon: "camera.fill", style: .secondary) {}
                    MonochromeButton("Voice Log", icon: "mic.fill", style: .secondary) {}
                    MonochromeButton("Manual Entry", icon: "pencil", style: .ghost) {}
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
            }
        }
        .navigationTitle("Log")
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
}
