import SwiftUI
import SwiftData

struct MealDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let meal: MealSummary
    var onDelete: (() -> Void)?

    @State private var showDeleteConfirm = false

    var body: some View {
        List {
            Section("Items") {
                ForEach(meal.items) { item in
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
            }

            Section("Totals") {
                HStack {
                    Text("Calories")
                    Spacer()
                    Text("\(Int(meal.totalCalories)) cal")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                HStack {
                    Text("Protein")
                    Spacer()
                    Text("\(Int(meal.totalProtein)) g")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                HStack {
                    Text("Carbs")
                    Spacer()
                    Text("\(Int(meal.totalCarbs)) g")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                HStack {
                    Text("Fat")
                    Spacer()
                    Text("\(Int(meal.totalFat)) g")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
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
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle(meal.mealType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Meal?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    let repo = MealRepository(modelContainer: modelContext.container)
                    try? await repo.deleteMeal(id: meal.id)
                    onDelete?()
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently remove this meal and all its items.")
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
