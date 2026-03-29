import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showManualEntry = false
    @State private var showCamera = false
    @State private var showBarcodeScanner = false
    @State private var showVoiceLog = false
    @State private var showFoodSearch = false

    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "plus.circle")
                    .font(QyraFont.regular(48))
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
                        showBarcodeScanner = true
                    }
                    MonochromeButton("Camera Scan", icon: "camera.fill", style: .secondary) {
                        showCamera = true
                    }
                    MonochromeButton("Voice Log", icon: "mic.fill", style: .secondary) {
                        showVoiceLog = true
                    }
                    MonochromeButton("Search Food", icon: "magnifyingglass", style: .secondary) {
                        showFoodSearch = true
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
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView()
        }
        .sheet(isPresented: $showBarcodeScanner) {
            BarcodeScannerView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showVoiceLog) {
            VoiceLogView(modelContainer: modelContext.container)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showFoodSearch) {
            FoodSearchView(modelContainer: modelContext.container)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    NavigationStack {
        LogView()
    }
    .modelContainer(for: [MealLog.self, MacroGoal.self, SyncRecord.self])
}
