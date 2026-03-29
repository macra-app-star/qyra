import SwiftUI
import SwiftData

struct MealDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let meal: MealSummary
    let modelContainer: ModelContainer
    var onDelete: (() -> Void)?

    @State private var showDeleteConfirm = false
    @State private var showAddItem = false
    @State private var items: [MealItemSummary]

    init(meal: MealSummary, modelContainer: ModelContainer, onDelete: (() -> Void)? = nil) {
        self.meal = meal
        self.modelContainer = modelContainer
        self.onDelete = onDelete
        self._items = State(initialValue: meal.items)
    }

    var body: some View {
        List {
            Section("Items") {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text(item.foodName)
                            .font(DesignTokens.Typography.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        HStack(spacing: DesignTokens.Spacing.md) {
                            macroLabel("\(Int(item.calories))", unit: "cal")
                            macroLabel("\(Int(item.protein))", unit: "P")
                            macroLabel("\(Int(item.carbs))", unit: "C")
                            macroLabel("\(Int(item.fat))", unit: "F")
                        }

                        if let serving = item.servingSize {
                            Text(serving)
                                .font(DesignTokens.Typography.caption)
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                        }
                    }
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                .onDelete { indexSet in
                    let idsToDelete = indexSet.map { items[$0].id }
                    items.remove(atOffsets: indexSet)
                    Task {
                        let repo = MealRepository(modelContainer: modelContainer)
                        for id in idsToDelete {
                            try? await repo.deleteMealItem(id: id)
                        }
                        onDelete?()
                    }
                    DesignTokens.Haptics.medium()
                }
            }

            Section("Totals") {
                totalRow("Calories", value: items.reduce(0) { $0 + $1.calories }, unit: "cal")
                totalRow("Protein", value: items.reduce(0) { $0 + $1.protein }, unit: "g")
                totalRow("Carbs", value: items.reduce(0) { $0 + $1.carbs }, unit: "g")
                totalRow("Fat", value: items.reduce(0) { $0 + $1.fat }, unit: "g")
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Meal")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle(meal.mealType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Delete Meal?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let repo = MealRepository(modelContainer: modelContainer)
                    try? await repo.deleteMeal(id: meal.id)
                    DesignTokens.Haptics.medium()
                    onDelete?()
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently remove this meal and all its items.")
        }
        .sheet(isPresented: $showAddItem, onDismiss: {
            onDelete?() // Trigger refresh in parent
        }) {
            AddItemToMealView(mealId: meal.id, modelContainer: modelContainer) { newItem in
                items.append(newItem)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func totalRow(_ label: String, value: Double, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(Int(value)) \(unit)")
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    private func macroLabel(_ value: String, unit: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(DesignTokens.Typography.subheadline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(unit)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }
}

// MARK: - Add Item to Existing Meal

struct AddItemToMealView: View {
    @Environment(\.dismiss) private var dismiss
    let mealId: UUID
    let modelContainer: ModelContainer
    var onAdd: ((MealItemSummary) -> Void)?

    @State private var foodName = ""
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var carbsText = ""
    @State private var fatText = ""

    private var canSave: Bool {
        !foodName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(caloriesText) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Food name", text: $foodName)
                }

                Section("Macros") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("0", text: $caloriesText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("0", text: $proteinText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("0", text: $carbsText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("Fat (g)")
                        Spacer()
                        TextField("0", text: $fatText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(DesignTokens.Colors.background)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let calories = Double(caloriesText) ?? 0
        let protein = Double(proteinText) ?? 0
        let carbs = Double(carbsText) ?? 0
        let fat = Double(fatText) ?? 0
        let name = foodName.trimmingCharacters(in: .whitespaces)
        let itemId = UUID()

        Task {
            let repo = MealRepository(modelContainer: modelContainer)
            try? await repo.addItemToMeal(
                mealId: mealId,
                item: NewMealItem(
                    foodName: name,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    servingSize: nil,
                    entryMethod: .manual
                )
            )

            let summary = MealItemSummary(
                id: itemId,
                foodName: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fat: fat,
                fiber: nil,
                sugar: nil,
                sodium: nil,
                servingSize: nil,
                entryMethod: .manual
            )
            onAdd?(summary)
            DesignTokens.Haptics.success()
            dismiss()
        }
    }
}
