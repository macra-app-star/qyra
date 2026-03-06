import SwiftUI
import SwiftData

struct PhotoAnalysisView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PhotoAnalysisViewModel
    let imageData: Data

    init(imageData: Data, modelContainer: ModelContainer) {
        self.imageData = imageData
        _viewModel = State(initialValue: PhotoAnalysisViewModel(modelContainer: modelContainer))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.Colors.background
                    .ignoresSafeArea()

                if viewModel.isAnalyzing {
                    LoadingOverlay(message: "Analyzing your food...")
                } else {
                    resultsContent
                }
            }
            .navigationTitle("Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                await viewModel.analyze(imageData: imageData)
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    DesignTokens.Haptics.success()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Results Content

    private var resultsContent: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                // Photo preview
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                        .padding(.horizontal, DesignTokens.Spacing.md)
                }

                if let error = viewModel.errorMessage {
                    errorSection(error)
                }

                // Detected items
                if !viewModel.items.isEmpty {
                    itemsSection

                    totalSection

                    mealTypeSection

                    logButton
                }

                // Retake button
                Button {
                    dismiss()
                } label: {
                    Text("Retake Photo")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
            .padding(.top, DesignTokens.Spacing.md)
        }
    }

    // MARK: - Sections

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Detected Items")
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                Button {
                    viewModel.addEmptyItem()
                } label: {
                    Label("Add Item", systemImage: "plus")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)

            ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                foodItemCard(item: item, index: index)
            }
        }
    }

    private func foodItemCard(item: FoodAnalysisResult, index: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text(item.name.isEmpty ? "New Item" : item.name)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                ConfidenceBadge(confidence: item.confidence)

                Button {
                    viewModel.removeItem(at: index)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            if let serving = item.servingSize {
                Text(serving)
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                macroLabel("Cal", value: item.calories, unit: "")
                macroLabel("P", value: item.protein, unit: "g")
                macroLabel("C", value: item.carbs, unit: "g")
                macroLabel("F", value: item.fat, unit: "g")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func macroLabel(_ label: String, value: Double, unit: String) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))\(unit)")
                .font(DesignTokens.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(label)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var totalSection: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            macroLabel("Total Cal", value: viewModel.totalCalories, unit: "")
            macroLabel("Protein", value: viewModel.totalProtein, unit: "g")
            macroLabel("Carbs", value: viewModel.totalCarbs, unit: "g")
            macroLabel("Fat", value: viewModel.totalFat, unit: "g")
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private var mealTypeSection: some View {
        Picker("Meal Type", selection: $viewModel.selectedMealType) {
            ForEach(MealType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private var logButton: some View {
        MonochromeButton("Log Meal", icon: "checkmark.circle.fill", style: .primary) {
            Task { await viewModel.logMeal() }
        }
        .disabled(!viewModel.canLog)
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func errorSection(_ message: String) -> some View {
        Text(message)
            .font(DesignTokens.Typography.callout)
            .foregroundStyle(DesignTokens.Colors.destructive)
            .multilineTextAlignment(.center)
            .padding(.horizontal, DesignTokens.Spacing.xl)
    }
}
