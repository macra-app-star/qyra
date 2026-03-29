import SwiftUI
import SwiftData

struct QuickAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var foodName = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""
    @State private var selectedMealType: MealType = .lunch
    @State private var isSaving = false

    var body: some View {
        VStack(spacing: 0) {
            // Food name (optional)
            TextField("Food name (optional)", text: $foodName)
                .font(.body)
                .padding(DesignTokens.Spacing.md)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, DesignTokens.Spacing.lg)

            // Macro inputs
            VStack(spacing: DesignTokens.Spacing.sm) {
                macroInput(label: "Calories", text: $caloriesText, unit: "cal", isPrimary: true)
                macroInput(label: "Protein", text: $proteinText, unit: "g")
                macroInput(label: "Carbs", text: $carbsText, unit: "g")
                macroInput(label: "Fat", text: $fatText, unit: "g")
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.md)

            // Meal type
            Picker("Meal", selection: $selectedMealType) {
                ForEach(MealType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Log button
            Button {
                Task { await logEntry() }
            } label: {
                Text(isSaving ? "Saving..." : "Log")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .disabled(!canLog || isSaving)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.lg)
        }
        .navigationTitle("Quick Add")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    // MARK: - Macro Input Row

    private func macroInput(label: String, text: Binding<String>, unit: String, isPrimary: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(isPrimary ? .headline : .body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .frame(width: 80, alignment: .leading)

            TextField("0", text: text)
                .font(isPrimary ? .title2.weight(.bold) : .body)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)

            Text(unit)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 30, alignment: .leading)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Validation

    private var canLog: Bool {
        guard let cals = Double(caloriesText), cals > 0 else { return false }
        return true
    }

    // MARK: - Save

    private func logEntry() async {
        isSaving = true
        defer { isSaving = false }

        let name = foodName.isEmpty ? "Quick add" : foodName
        let cals = Double(caloriesText) ?? 0
        let protein = Double(proteinText) ?? 0
        let carbs = Double(carbsText) ?? 0
        let fat = Double(fatText) ?? 0

        let repo = MealRepository(modelContainer: modelContext.container)
        let item = NewMealItem(
            foodName: name,
            calories: cals,
            protein: protein,
            carbs: carbs,
            fat: fat,
            entryMethod: .manual
        )

        try? await repo.addMeal(
            date: Date(),
            mealType: selectedMealType,
            items: [item]
        )

        DesignTokens.Haptics.success()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        QuickAddView()
    }
}
