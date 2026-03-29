import SwiftUI
import SwiftData

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ManualEntryViewModel

    init(modelContainer: ModelContainer) {
        _viewModel = State(initialValue: ManualEntryViewModel(modelContainer: modelContainer))
    }

    init(viewModel: ManualEntryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food name", text: $viewModel.foodName)

                    Picker("Meal", selection: $viewModel.selectedMealType) {
                        ForEach(MealType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Nutrition") {
                    macroField("Calories", text: $viewModel.caloriesText, unit: "cal")
                    macroField("Protein", text: $viewModel.proteinText, unit: "g")
                    macroField("Carbs", text: $viewModel.carbsText, unit: "g")
                    macroField("Fat", text: $viewModel.fatText, unit: "g")
                }

                Section("Optional") {
                    macroField("Fiber", text: $viewModel.fiberText, unit: "g")
                    macroField("Sugar", text: $viewModel.sugarText, unit: "g")
                    macroField("Sodium", text: $viewModel.sodiumText, unit: "mg")
                    TextField("Serving size (e.g. 1 cup)", text: $viewModel.servingSize)
                }

                if let warning = viewModel.validationWarning {
                    Section {
                        Text(warning)
                            .foregroundStyle(.orange)
                            .font(DesignTokens.Typography.caption)
                    }
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(DesignTokens.Typography.caption)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    DesignTokens.Haptics.success()
                    dismiss()
                }
            }
        }
    }

    private func macroField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

#Preview {
    ManualEntryView(
        modelContainer: try! ModelContainer(for: MealLog.self, MacroGoal.self, SyncRecord.self)
    )
}
