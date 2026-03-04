import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showManualEntry = false
    @State private var showComingSoon = false
    @State private var comingSoonFeature = ""

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
                    MonochromeButton("Scan Barcode", icon: "barcode.viewfinder", style: .primary) {
                        comingSoonFeature = "Barcode scanning"
                        showComingSoon = true
                    }
                    MonochromeButton("Camera Scan", icon: "camera.fill", style: .secondary) {
                        comingSoonFeature = "Camera scanning"
                        showComingSoon = true
                    }
                    MonochromeButton("Voice Log", icon: "mic.fill", style: .secondary) {
                        comingSoonFeature = "Voice logging"
                        showComingSoon = true
                    }
                    MonochromeButton("Manual Entry", icon: "pencil", style: .ghost) {
                        showManualEntry = true
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xl)
            }
        }
        .navigationTitle("Log")
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(modelContainer: modelContext.container)
        }
        .alert(comingSoonFeature, isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comingSoonFeature) is coming in a future update.")
        }
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
