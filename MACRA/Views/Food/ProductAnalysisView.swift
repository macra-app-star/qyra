import SwiftUI
import SwiftData

/// Rich product analysis card — shown after barcode scan.
/// Displays nutrition, health score, ingredients, additives, allergens.
struct ProductAnalysisView: View {
    let product: ProductAnalysis
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var quantity: Int = 1
    @State private var mealType: MealType = .lunch
    @State private var didSave = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero: Product image + info + health score
                    productHeader
                        .padding(.bottom, DesignTokens.Spacing.lg)

                    // Nutrition breakdown
                    nutritionSection
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)

                    // Additives
                    if !product.additives.isEmpty {
                        additivesSection
                            .padding(.top, DesignTokens.Spacing.lg)
                            .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }

                    // Allergens
                    if !product.allergens.isEmpty {
                        allergensSection
                            .padding(.top, DesignTokens.Spacing.lg)
                            .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }

                    // Labels
                    if !product.labels.isEmpty {
                        labelsSection
                            .padding(.top, DesignTokens.Spacing.lg)
                            .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }

                    // Ingredients
                    if let ingredients = product.ingredients, !ingredients.isEmpty {
                        ingredientsSection(ingredients)
                            .padding(.top, DesignTokens.Spacing.lg)
                            .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    }

                    // Log to meal
                    logSection
                        .padding(.top, DesignTokens.Spacing.xl)
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)
                        .padding(.bottom, DesignTokens.Spacing.xxl)
                }
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onChange(of: didSave) { _, saved in
                if saved {
                    DesignTokens.Haptics.success()
                    dismiss()
                }
            }
        }
        .onAppear { autoSelectMealType() }
    }

    // MARK: - Product Header

    private var productHeader: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Product image
            if let urlString = product.imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(DesignTokens.Colors.neutral90)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                        }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(product.name)
                    .font(QyraFont.bold(18))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                if let brand = product.brand {
                    Text(brand)
                        .font(QyraFont.regular(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                // Health score badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(product.healthRating.color)
                        .frame(width: 12, height: 12)
                    Text("\(product.healthScore)/100")
                        .font(QyraFont.bold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text(product.healthRating.label)
                        .font(QyraFont.medium(14))
                        .foregroundStyle(product.healthRating.color)
                }
                .padding(.top, 2)

                if let nutriScore = product.nutriScore?.uppercased() {
                    Text("Nutri-Score \(nutriScore)")
                        .font(QyraFont.medium(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            Spacer()
        }
        .padding(DesignTokens.Layout.screenMargin)
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Nutrition")
                    .font(QyraFont.bold(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                Text("per serving (\(product.servingSize ?? "100g"))")
                    .font(QyraFont.regular(13))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            VStack(spacing: 0) {
                nutrientRow("Calories", value: "\(Int(product.calories)) Cal", level: calorieLevel)
                Divider()
                nutrientRow("Protein", value: "\(Int(product.protein))g", level: .low) // protein is always good
                Divider()
                nutrientRow("Carbs", value: "\(Int(product.carbs))g", level: nil)
                Divider()
                nutrientRow("Fat", value: "\(Int(product.fat))g", level: product.nutrientLevels?.fat)
                if let sugar = product.sugar {
                    Divider()
                    nutrientRow("Sugar", value: "\(Int(sugar))g", level: product.nutrientLevels?.sugars)
                }
                if let sodium = product.sodium {
                    Divider()
                    nutrientRow("Sodium", value: "\(Int(sodium * 1000))mg", level: product.nutrientLevels?.salt)
                }
                if let fiber = product.fiber {
                    Divider()
                    nutrientRow("Fiber", value: "\(Int(fiber))g", level: .low)
                }
                if let satFat = product.saturatedFat {
                    Divider()
                    nutrientRow("Saturated Fat", value: "\(Int(satFat))g", level: product.nutrientLevels?.saturatedFat)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private var calorieLevel: NutrientLevel? {
        if product.calories > 400 { return .high }
        if product.calories > 200 { return .moderate }
        return .low
    }

    private func nutrientRow(_ name: String, value: String, level: NutrientLevel?) -> some View {
        HStack {
            if let level {
                Circle()
                    .fill(level.color)
                    .frame(width: 10, height: 10)
            }
            Text(name)
                .font(QyraFont.medium(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Spacer()
            Text(value)
                .font(QyraFont.semibold(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    // MARK: - Additives Section

    private var additivesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Additives")
                .font(QyraFont.bold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(spacing: 0) {
                ForEach(product.additives.prefix(8), id: \.self) { additive in
                    HStack {
                        Circle()
                            .fill(additiveRiskColor(additive))
                            .frame(width: 10, height: 10)
                        Text(additive)
                            .font(QyraFont.medium(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Spacer()
                        Text(additiveRiskLabel(additive))
                            .font(QyraFont.regular(12))
                            .foregroundStyle(additiveRiskColor(additive))
                    }
                    .padding(.vertical, DesignTokens.Spacing.sm)

                    if additive != product.additives.prefix(8).last {
                        Divider()
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private func additiveRiskColor(_ additive: String) -> Color {
        let high = ["bht", "bha", "e621", "e951", "e950", "e150d", "e171"]
        let lowered = additive.lowercased()
        if high.contains(where: { lowered.contains($0) }) { return .red }
        return .orange
    }

    private func additiveRiskLabel(_ additive: String) -> String {
        let lowered = additive.lowercased()
        let highRisk = ["bht", "bha", "e621", "e951", "e950", "e150d", "e171"]
        if highRisk.contains(where: { lowered.contains($0) }) { return "High risk" }
        return "Moderate"
    }

    // MARK: - Allergens Section

    private var allergensSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Allergens")
                .font(QyraFont.bold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Contains: \(product.allergens.joined(separator: ", "))")
                    .font(QyraFont.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            .padding(DesignTokens.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Labels Section

    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Labels")
                .font(QyraFont.bold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            FlowLayout(spacing: DesignTokens.Spacing.sm) {
                ForEach(product.labels, id: \.self) { label in
                    Text(label)
                        .font(QyraFont.medium(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm + 2)
                        .padding(.vertical, DesignTokens.Spacing.xs + 1)
                        .background(DesignTokens.Colors.secondaryFill)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Ingredients Section

    private func ingredientsSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Ingredients")
                .font(QyraFont.bold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(text)
                .font(QyraFont.regular(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .lineSpacing(4)
                .padding(DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Colors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Log Section

    private var logSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Meal type picker
            Picker("Meal", selection: $mealType) {
                ForEach(MealType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)

            // Quantity
            HStack {
                Text("Quantity")
                    .font(QyraFont.medium(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Spacer()
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button {
                        if quantity > 1 { quantity -= 1 }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    Text("\(quantity)")
                        .font(QyraFont.bold(18))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .frame(minWidth: 30)
                    Button {
                        if quantity < 10 { quantity += 1 }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DesignTokens.Colors.tint)
                    }
                }
            }

            // Log button
            Button {
                Task { await logProduct() }
            } label: {
                Text("Add to Meal Log")
                    .font(QyraFont.semibold(17))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Layout.buttonHeight)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius))
            }
        }
    }

    // MARK: - Actions

    private func logProduct() async {
        var result = product.toFoodAnalysisResult()

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
                servingSize: "\(quantity)x \(result.servingSize ?? "serving")",
                confidence: result.confidence,
                brand: result.brand,
                barcode: result.barcode,
                imageURL: result.imageURL
            )
        }

        let newItem = result.toNewMealItem(entryMethod: .barcode)
        let repo = MealRepository(modelContainer: modelContext.container)

        do {
            try await repo.addMeal(date: Date(), mealType: mealType, items: [newItem])
            didSave = true
        } catch {
            // Error handling — could add toast
        }
    }

    private func autoSelectMealType() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<10: mealType = .breakfast
        case 10..<14: mealType = .lunch
        case 14..<17: mealType = .snack
        default: mealType = .dinner
        }
    }
}

// FlowLayout is defined in Qyra/Components/FlowLayout.swift
