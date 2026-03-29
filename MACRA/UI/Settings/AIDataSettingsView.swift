import SwiftUI

// Settings screen for AI analysis mode, offline data downloads, and exercise expansion.

struct AIDataSettingsView: View {
    @ObservedObject private var exerciseImport = ExerciseImportService.shared
    @State private var analysisMode: FoodAnalysisPipeline.AnalysisMode = .auto
    @State private var cachedFoodCount: Int = 0
    @State private var exerciseCount: Int = 0
    @State private var isOfflineAvailable = false

    var body: some View {
        List {
            // MARK: - Food Analysis
            Section {
                Picker("Analysis mode", selection: $analysisMode) {
                    Text("Auto (recommended)").tag(FoodAnalysisPipeline.AnalysisMode.auto)
                    Text("Offline only").tag(FoodAnalysisPipeline.AnalysisMode.offlineOnly)
                    Text("Cloud only (Gemini)").tag(FoodAnalysisPipeline.AnalysisMode.cloudOnly)
                }
                .onChange(of: analysisMode) { _, mode in
                    FoodAnalysisPipeline.shared.analysisMode = mode
                }

                HStack {
                    Text("Offline model")
                    Spacer()
                    Text(isOfflineAvailable ? "Available" : "Not installed")
                        .foregroundStyle(isOfflineAvailable ? DesignTokens.Colors.success : DesignTokens.Colors.textTertiary)
                }
            } header: {
                Text("Food Recognition")
            } footer: {
                Text("Auto mode uses on-device AI when available, falling back to cloud AI (Gemini) for higher accuracy. Your photos are never stored on our servers.")
            }

            // MARK: - Cached Data
            Section {
                HStack {
                    Label("Cached foods", systemImage: "fork.knife")
                    Spacer()
                    Text("\(cachedFoodCount) products")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                HStack {
                    Label("Exercise database", systemImage: "dumbbell.fill")
                    Spacer()
                    Text("\(exerciseCount) \(exerciseCount == 1 ? "exercise" : "exercises")")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            } header: {
                Text("Offline Data")
            } footer: {
                Text("Food products are cached automatically as you search and scan. The exercise database downloads on first launch.")
            }

            // MARK: - Expand Exercise DB
            Section {
                Button {
                    Task { await exerciseImport.importExpandedExerciseDB() }
                } label: {
                    HStack {
                        Label("Download expanded database", systemImage: "arrow.down.circle")
                            .foregroundStyle(DesignTokens.Colors.tint)
                        Spacer()
                        if exerciseImport.isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(exerciseImport.isImporting)
            } header: {
                Text("Exercise Expansion")
            } footer: {
                Text("Downloads 1,300+ additional exercises with GIF animations from ExerciseDB. Requires internet connection (~2 MB).")
            }

            // MARK: - Privacy
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data privacy")
                            .font(QyraFont.semibold(15))
                        Text("Food photos are analyzed on-device when possible. Cloud analysis (Gemini) sends image data to Google's servers for processing. No images are stored permanently.")
                            .font(QyraFont.regular(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(DesignTokens.Colors.success)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle("AI & Offline Data")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            analysisMode = FoodAnalysisPipeline.shared.analysisMode
            cachedFoodCount = await NutritionService.shared.cachedProductCount()
            exerciseCount = await ExerciseImportService.shared.totalExerciseCount()
            isOfflineAvailable = await FoodAnalysisPipeline.shared.offlineAvailable
        }
    }
}

#Preview {
    NavigationStack {
        AIDataSettingsView()
    }
}
