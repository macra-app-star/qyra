import SwiftUI

struct RestaurantOrderView: View {
    let restaurantName: String
    @State private var orderText = ""
    @State private var isEstimating = false
    @State private var estimatedCalories: Int?
    @State private var estimatedProtein: Int?
    @State private var estimatedCarbs: Int?
    @State private var estimatedFat: Int?
    @State private var showEstimate = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Restaurant header
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(DesignTokens.Typography.icon(48))
                        .foregroundStyle(DesignTokens.Colors.accent)

                    Text(restaurantName)
                        .font(DesignTokens.Typography.headlineFont(20))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
                .padding(.top, DesignTokens.Spacing.lg)

                // Order description input
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("What did you order?")
                        .font(DesignTokens.Typography.semibold(15))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    TextField(
                        "e.g. Grilled salmon with rice and broccoli",
                        text: $orderText,
                        axis: .vertical
                    )
                    .font(DesignTokens.Typography.bodyFont(15))
                    .lineLimit(3...6)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .padding(.horizontal, DesignTokens.Spacing.md)

                if showEstimate {
                    macroEstimateCard
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // Primary action button
                Button {
                    if showEstimate {
                        DesignTokens.Haptics.success()
                        dismiss()
                    } else {
                        estimateMacros()
                    }
                } label: {
                    Group {
                        if isEstimating {
                            ProgressView()
                                .tint(DesignTokens.Colors.surfaceElevated)
                        } else {
                            Text(showEstimate ? "Log Meal" : "Estimate Macros")
                                .font(DesignTokens.Typography.semibold(17))
                        }
                    }
                    .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Layout.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Layout.buttonCornerRadius)
                            .fill(DesignTokens.Colors.buttonPrimary)
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .disabled(orderTextIsEmpty || isEstimating)
                .opacity(orderTextIsEmpty ? 0.5 : 1.0)

                // Disclaimer
                Text("Estimates are approximate and may vary")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(.bottom, DesignTokens.Spacing.md)
            }
            .navigationTitle("Log Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(DesignTokens.Typography.medium(16))
                }
            }
        }
    }

    // MARK: - Subviews

    private var macroEstimateCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Estimated macros")
                .font(DesignTokens.Typography.semibold(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.lg) {
                macroColumn(label: "Cal", value: estimatedCalories ?? 0, color: DesignTokens.Colors.textPrimary)
                macroColumn(label: "Protein", value: estimatedProtein ?? 0, color: DesignTokens.Colors.ringProtein)
                macroColumn(label: "Carbs", value: estimatedCarbs ?? 0, color: DesignTokens.Colors.ringCarbs)
                macroColumn(label: "Fat", value: estimatedFat ?? 0, color: DesignTokens.Colors.ringFat)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .premiumCard()
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func macroColumn(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text("\(value)")
                .font(DesignTokens.Typography.numeric(24))
                .foregroundStyle(color)
            Text(label)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    // MARK: - Helpers

    private var orderTextIsEmpty: Bool {
        orderText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func estimateMacros() {
        isEstimating = true
        Task { @MainActor in
            // Simulate network delay for estimation
            try? await Task.sleep(for: .seconds(0.8))

            let words = orderText.lowercased()
            let hasProtein = words.contains("chicken") ||
                words.contains("salmon") ||
                words.contains("steak") ||
                words.contains("fish") ||
                words.contains("shrimp") ||
                words.contains("beef") ||
                words.contains("pork") ||
                words.contains("turkey") ||
                words.contains("tofu")
            let hasCarbs = words.contains("rice") ||
                words.contains("pasta") ||
                words.contains("bread") ||
                words.contains("fries") ||
                words.contains("potato") ||
                words.contains("noodle") ||
                words.contains("pizza")
            let hasFat = words.contains("fried") ||
                words.contains("cream") ||
                words.contains("cheese") ||
                words.contains("butter") ||
                words.contains("oil")

            let wordCount = orderText.split(separator: " ").count
            let baseCalories = max(300, min(1200, wordCount * 80 + (hasProtein ? 200 : 100)))

            estimatedCalories = baseCalories
            estimatedProtein = hasProtein ? Int.random(in: 28...45) : Int.random(in: 12...25)
            estimatedCarbs = hasCarbs ? Int.random(in: 40...70) : Int.random(in: 15...35)
            estimatedFat = hasFat ? Int.random(in: 20...35) : Int.random(in: 12...25)

            withAnimation(DesignTokens.Anim.spring) {
                showEstimate = true
            }
            isEstimating = false
        }
    }
}

#Preview {
    RestaurantOrderView(restaurantName: "The Sushi Place")
}
