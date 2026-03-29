import SwiftUI
import SwiftData

struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let food: FoodAnalysisResult
    @State var mealType: MealType
    @State private var quantity: Double = 1.0
    @State private var didSave = false
    @State private var errorMessage: String?
    let onSaved: (() -> Void)?

    static var defaultMealType: MealType {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<10: return .breakfast
        case 10..<14: return .lunch
        case 14..<17: return .snack
        default: return .dinner
        }
    }

    init(food: FoodAnalysisResult, mealType: MealType? = nil, modelContainer: ModelContainer? = nil, onSaved: (() -> Void)? = nil) {
        self.food = food
        _mealType = State(initialValue: mealType ?? FoodDetailView.defaultMealType)
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

                    if food.confidence < 80 {
                        Text("AI Estimated")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(DesignTokens.Colors.surfaceElevated)
                            .clipShape(Capsule())
                    }
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

                Button {
                    Task { await addToLog(asFavorite: true) }
                } label: {
                    Text("Save to Favorites")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                }

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
                macroCard("Calories", value: food.calories * quantity, unit: "", large: true)
                macroCard("Protein", value: food.protein * quantity, unit: "g", large: true)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                macroCard("Carbs", value: food.carbs * quantity, unit: "g", large: false)
                macroCard("Fat", value: food.fat * quantity, unit: "g", large: false)
            }

            if food.fiber != nil || food.sugar != nil || food.sodium != nil {
                HStack(spacing: DesignTokens.Spacing.md) {
                    if let fiber = food.fiber {
                        macroCard("Fiber", value: fiber * quantity, unit: "g", large: false)
                    }
                    if let sugar = food.sugar {
                        macroCard("Sugar", value: sugar * quantity, unit: "g", large: false)
                    }
                    if let sodium = food.sodium {
                        macroCard("Sodium", value: sodium * 1000 * quantity, unit: "mg", large: false)
                    }
                }
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

    private static let quantitySteps: [Double] = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]

    private var quantitySelector: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Servings")
                    .font(DesignTokens.Typography.body)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        if let idx = Self.quantitySteps.firstIndex(of: quantity), idx > 0 {
                            withAnimation(DesignTokens.Anim.quick) {
                                quantity = Self.quantitySteps[idx - 1]
                            }
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(QyraFont.regular(28))
                            .foregroundStyle(quantity <= Self.quantitySteps.first ?? 0.5
                                             ? DesignTokens.Colors.textTertiary
                                             : DesignTokens.Colors.textSecondary)
                    }
                    .disabled(quantity <= Self.quantitySteps.first ?? 0.5)

                    Text(quantity.truncatingRemainder(dividingBy: 1) == 0
                         ? "\(Int(quantity))"
                         : String(format: "%.1f", quantity))
                        .font(DesignTokens.Typography.title3)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .frame(width: 44)
                        .contentTransition(.numericText())

                    Button {
                        if let idx = Self.quantitySteps.firstIndex(of: quantity),
                           idx < Self.quantitySteps.count - 1 {
                            withAnimation(DesignTokens.Anim.quick) {
                                quantity = Self.quantitySteps[idx + 1]
                            }
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(QyraFont.regular(28))
                            .foregroundStyle(quantity >= Self.quantitySteps.last ?? 3.0
                                             ? DesignTokens.Colors.textTertiary
                                             : DesignTokens.Colors.textSecondary)
                    }
                    .disabled(quantity >= Self.quantitySteps.last ?? 3.0)
                }
            }

            // Serving size display
            if let serving = food.servingSize {
                Text("Serving: \(serving)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Save

    private func addToLog(asFavorite: Bool = false) async {
        var result = food

        if quantity != 1.0 {
            let qtyLabel = quantity.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(quantity))"
                : String(format: "%.1f", quantity)
            result = FoodAnalysisResult(
                name: result.name,
                calories: result.calories * quantity,
                protein: result.protein * quantity,
                carbs: result.carbs * quantity,
                fat: result.fat * quantity,
                fiber: result.fiber.map { $0 * quantity },
                sugar: result.sugar.map { $0 * quantity },
                sodium: result.sodium.map { $0 * quantity },
                servingSize: "\(qtyLabel)x \(result.servingSize ?? "serving")",
                confidence: result.confidence,
                brand: result.brand
            )
        }

        let item = result.toNewMealItem(entryMethod: .manual, isFavorite: asFavorite)
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
