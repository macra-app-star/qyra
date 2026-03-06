import SwiftUI

struct BarcodeResultView: View {
    @Bindable var viewModel: BarcodeScannerViewModel
    let product: FoodAnalysisResult

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Product header
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green.opacity(0.85))

                    Text(product.name)
                        .font(DesignTokens.Typography.title2)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    if let brand = product.brand {
                        Text(brand)
                            .font(DesignTokens.Typography.callout)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    if let barcode = product.barcode {
                        Text("Barcode: \(barcode)")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }

                    ConfidenceBadge(confidence: product.confidence)
                }
                .padding(.top, DesignTokens.Spacing.md)

                // Nutrition card
                nutritionSection

                // Serving + quantity
                servingSection

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
                    MonochromeButton("Log to \(viewModel.selectedMealType.displayName)", icon: "checkmark.circle.fill", style: .primary) {
                        Task { await viewModel.logProduct() }
                    }

                    MonochromeButton("Scan Again", icon: "barcode.viewfinder", style: .ghost) {
                        viewModel.rescan()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
    }

    private var nutritionSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Nutrition per serving")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if let serving = product.servingSize {
                Text("Serving: \(serving)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }

            HStack(spacing: DesignTokens.Spacing.md) {
                macroTile("Calories", value: product.calories * Double(viewModel.quantity), unit: "")
                macroTile("Protein", value: product.protein * Double(viewModel.quantity), unit: "g")
                macroTile("Carbs", value: product.carbs * Double(viewModel.quantity), unit: "g")
                macroTile("Fat", value: product.fat * Double(viewModel.quantity), unit: "g")
            }

            if product.fiber != nil || product.sugar != nil || product.sodium != nil {
                HStack(spacing: DesignTokens.Spacing.md) {
                    if let fiber = product.fiber {
                        macroTile("Fiber", value: fiber * Double(viewModel.quantity), unit: "g")
                    }
                    if let sugar = product.sugar {
                        macroTile("Sugar", value: sugar * Double(viewModel.quantity), unit: "g")
                    }
                    if let sodium = product.sodium {
                        macroTile("Sodium", value: sodium * Double(viewModel.quantity), unit: "g")
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func macroTile(_ label: String, value: Double, unit: String) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(value))\(unit)")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(label)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var servingSection: some View {
        HStack {
            Text("Quantity")
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            HStack(spacing: DesignTokens.Spacing.md) {
                Button {
                    if viewModel.quantity > 1 { viewModel.quantity -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Text("\(viewModel.quantity)")
                    .font(DesignTokens.Typography.title3)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .frame(width: 40)

                Button {
                    if viewModel.quantity < 10 { viewModel.quantity += 1 }
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
}
