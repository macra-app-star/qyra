import SwiftUI
import SwiftData

struct VoiceLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VoiceLogViewModel

    init(modelContainer: ModelContainer) {
        _viewModel = State(initialValue: VoiceLogViewModel(modelContainer: modelContainer))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                if !viewModel.hasPermission {
                    permissionView
                } else if viewModel.isAnalyzing {
                    LoadingOverlay(message: "Analyzing your meal...")
                } else if !viewModel.items.isEmpty {
                    resultsView
                } else {
                    recordingView
                }
            }
            .navigationTitle("Voice Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.stopRecording()
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.checkPermission()
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    DesignTokens.Haptics.success()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            // Transcription area
            if !viewModel.transcription.isEmpty {
                Text(viewModel.transcription)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    .padding(.horizontal, DesignTokens.Spacing.lg)
            } else {
                Text(viewModel.isRecording
                    ? "Listening... describe your meal"
                    : "Tap the microphone and describe what you ate"
                )
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }

            // Waveform
            WaveformView(isRecording: viewModel.isRecording)
                .padding(.horizontal, DesignTokens.Spacing.xl)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.destructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }

            // Mic button
            Button {
                DesignTokens.Haptics.medium()
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? DesignTokens.Colors.destructive : DesignTokens.Colors.accent)
                        .frame(width: 80, height: 80)

                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                        .font(QyraFont.regular(32))
                        .foregroundStyle(viewModel.isRecording ? .white : .black)
                }
            }

            Text(viewModel.isRecording ? "Tap to stop" : "Tap to record")
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            // Example text
            if !viewModel.isRecording && viewModel.transcription.isEmpty {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    Text("Examples:")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)

                    Text("\"I had a chicken burrito with rice and beans\"")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .italic()

                    Text("\"Two eggs, toast with butter, and orange juice\"")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .italic()
                }
                .padding(.top, DesignTokens.Spacing.md)
            }

            Spacer()
        }
    }

    // MARK: - Results View

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Transcription
                Text("\"\(viewModel.transcription)\"")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.md)

                // Items
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    foodItemRow(item: item, index: index)
                }

                // Totals
                HStack(spacing: DesignTokens.Spacing.md) {
                    macroLabel("Cal", value: viewModel.totalCalories)
                    macroLabel("P", value: viewModel.totalProtein)
                    macroLabel("C", value: viewModel.totalCarbs)
                    macroLabel("F", value: viewModel.totalFat)
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                .padding(.horizontal, DesignTokens.Spacing.md)

                // Meal type
                Picker("Meal Type", selection: $viewModel.selectedMealType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignTokens.Spacing.md)

                // Actions
                VStack(spacing: DesignTokens.Spacing.sm) {
                    MonochromeButton("Log Meal", icon: "checkmark.circle.fill", style: .primary) {
                        Task { await viewModel.logMeal() }
                    }
                    .disabled(!viewModel.canLog)

                    MonochromeButton("Try Again", icon: "mic.fill", style: .ghost) {
                        viewModel.reset()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
    }

    private func foodItemRow(item: FoodAnalysisResult, index: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("\(Int(item.calories)) cal \u{2022} \(Int(item.protein))g P \u{2022} \(Int(item.carbs))g C \u{2022} \(Int(item.fat))g F")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            ConfidenceBadge(confidence: item.confidence)

            Button {
                viewModel.removeItem(at: index)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func macroLabel(_ label: String, value: Double) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(label)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "mic.slash.fill")
                .font(QyraFont.regular(48))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            Text("Microphone Access Required")
                .font(DesignTokens.Typography.title2)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Enable microphone and speech recognition in Settings.")
                .font(DesignTokens.Typography.callout)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(DesignTokens.Typography.headline)
            .foregroundStyle(DesignTokens.Colors.accent)
        }
        .padding(DesignTokens.Spacing.xl)
    }
}
