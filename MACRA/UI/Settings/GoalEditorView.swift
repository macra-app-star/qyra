import SwiftUI
import SwiftData

struct GoalEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: GoalEditorViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                Form {
                    Section("Daily Targets") {
                        goalField("Calories", text: Binding(
                            get: { vm.calorieText },
                            set: { vm.calorieText = $0 }
                        ), unit: "cal")
                        goalField("Protein", text: Binding(
                            get: { vm.proteinText },
                            set: { vm.proteinText = $0 }
                        ), unit: "g")
                        goalField("Carbs", text: Binding(
                            get: { vm.carbText },
                            set: { vm.carbText = $0 }
                        ), unit: "g")
                        goalField("Fat", text: Binding(
                            get: { vm.fatText },
                            set: { vm.fatText = $0 }
                        ), unit: "g")
                    }

                    Section("Goal Type") {
                        Picker("Goal", selection: Binding(
                            get: { vm.goalType },
                            set: { vm.goalType = $0 }
                        )) {
                            ForEach(GoalType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Activity Level") {
                        Picker("Activity", selection: Binding(
                            get: { vm.activityLevel },
                            set: { vm.activityLevel = $0 }
                        )) {
                            ForEach(ActivityLevel.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                    }
                }
                .navigationTitle("Edit Goals")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task { await vm.save() }
                        }
                        .disabled(!vm.canSave)
                    }
                }
                .onChange(of: vm.didSave) { _, saved in
                    if saved {
                        DesignTokens.Haptics.success()
                        dismiss()
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                let vm = GoalEditorViewModel(modelContainer: modelContext.container)
                viewModel = vm
                await vm.load()
            }
        }
    }

    private func goalField(_ label: String, text: Binding<String>, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            Text(unit)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .frame(width: 30, alignment: .leading)
        }
    }
}

#Preview {
    NavigationStack {
        GoalEditorView()
    }
    .modelContainer(for: [MacroGoal.self, SyncRecord.self])
}
