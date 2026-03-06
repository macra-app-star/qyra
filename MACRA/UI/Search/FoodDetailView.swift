import SwiftUI
import SwiftData

struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let food: USDAFoodResult
    @State var mealType: MealType
    @State private var quantity: Int = 1
    @State private var didSave = false
    @State private var errorMessage: String?
    let onSaved: (() -> Void)?

    init(food: USDAFoodResult, mealType: MealType, modelContainer: ModelContainer?, onSaved: (() -> Void)? = nil) {
        self.food = food
        _mealType = State(initialValue: mealType)
        self.onSaved = onSaved
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text(food.name)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let brand = food.brand {
                        Text(brand)
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    Text(food.dataType)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(DesignTokens.Colors.surfaceElevated)
                        .clipShape(Capsule())
                }

                // Macros
                nutritionGrid

                // Quantity
                quantitySelector

                // Meal type
                Picker("Meal Type", selection: $mealType) {
                    ForEach(MealType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignTokens.Spacing.md)

                // Add button
                MonochromeButton("Add to Log", icon: "plus.circle.fill", style: .primary) {
                    Task { await addToLog() }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)

                if let error = errorMessage {
                    Text(error)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.destructive)
                }
            }
            .padding(.top, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Nutrition Grid

    private var nutritionGrid: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack(spacing: DesignTokens.Spacing.md) {
                macroCard("Calories", value: food.calories * Double(quantity), unit: "", large: true)
                macroCard("Protein", value: food.protein * Double(quantity), unit: "g", large: true)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                macroCard("Carbs", value: food.carbs * Double(quantity), unit: "g", large: false)
                macroCard("Fat", value: food.fat * Double(quantity), unit: "g", large: false)
            }

            if food.fiber != nil || food.sugar != nil || food.sodium != nil {
                HStack(spacing: DesignTokens.Spacing.md) {
                    if let fiber = food.fiber {
                        macroCard("Fiber", value: fiber * Double(quantity), unit: "g", large: false)
                    }
                    if let sugar = food.sugar {
                        macroCard("Sugar", value: sugar * Double(quantity), unit: "g", large: false)
                    }
                    if let sodium = food.sodium {
                        macroCard("Sodium", value: sodium * 1000 * Double(quantity), unit: "mg", large: false)
                    }
                }
            }

            if let serving = food.servingSize {
                Text("Per serving: \(serving)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func macroCard(_ label: String, value: Double, unit: String, large: Bool) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value))\(unit)")
                .font(large ? DesignTokens.Typography.title2 : DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Quantity

    private var quantitySelector: some View {
        HStack {
            Text("Servings")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            HStack(spacing: DesignTokens.Spacing.md) {
                Button {
                    if quantity > 1 { quantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Text("\(quantity)")
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .frame(width: 40)

                Button {
                    if quantity < 10 { quantity += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Save

    private func addToLog() async {
        var result = food.toFoodAnalysisResult()

        if quantity > 1 {
            result = FoodAnalysisResult(
                name: result.name,
                calories: result.calories * Double(quantity),
                protein: result.protein * Double(quantity),
                carbs: result.carbs * Double(quantity),
                fat: result.fat * Double(quantity),
                fiber: result.fiber.map { $0 * Double(quantity) },
                sugar: result.sugar.map { $0 * Double(quantity) },
                sodium: result.sodium.map { $0 * Double(quantity) },
                servingSize: quantity > 1 ? "\(quantity)x \(result.servingSize ?? "serving")" : result.servingSize,
                confidence: result.confidence,
                brand: result.brand
            )
        }

        let item = result.toNewMealItem(entryMethod: .manual)
        let repo = MealRepository(modelContainer: modelContext.container)

        do {
            try await repo.addMeal(date: Date(), mealType: mealType, items: [item])
            DesignTokens.Haptics.success()
            onSaved?()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}
