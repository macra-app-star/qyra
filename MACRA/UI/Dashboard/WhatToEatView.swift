import SwiftUI

struct WhatToEatView: View {
    let remainingCalories: Double
    let remainingProtein: Double
    let remainingCarbs: Double
    let remainingFat: Double

    @State private var selectedFilter = "All"
    @Environment(\.dismiss) private var dismiss

    private let filters = ["All", "Balanced", "High Protein", "Indulgent", "Quick Snack"]

    private struct FoodSuggestion: Identifiable {
        let id = UUID()
        let emoji: String
        let name: String
        let description: String
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let category: String
    }

    private var suggestions: [FoodSuggestion] {
        let all = [
            FoodSuggestion(emoji: "🥣", name: "Greek Yogurt with Granola and Berries", description: "Perfect protein-rich late night option with complex carbs to help you sleep.", calories: 320, protein: 20, carbs: 45, fat: 8, category: "High Protein"),
            FoodSuggestion(emoji: "🍌", name: "Peanut Butter Toast with Banana", description: "Classic comfort food that delivers protein and satisfying carbs for late night.", calories: 380, protein: 15, carbs: 48, fat: 16, category: "Quick Snack"),
            FoodSuggestion(emoji: "🥤", name: "Protein Smoothie with Oats", description: "Easy to digest liquid meal with protein powder, oats, and fruit.", calories: 350, protein: 25, carbs: 40, fat: 10, category: "High Protein"),
            FoodSuggestion(emoji: "🥗", name: "Chicken Caesar Salad", description: "Light yet satisfying with lean protein and fresh vegetables.", calories: 420, protein: 35, carbs: 15, fat: 22, category: "Balanced"),
            FoodSuggestion(emoji: "🍕", name: "Margherita Pizza Slice", description: "A satisfying indulgence with mozzarella and fresh basil.", calories: 280, protein: 12, carbs: 32, fat: 12, category: "Indulgent"),
        ]
        if selectedFilter == "All" { return all }
        return all.filter { $0.category == selectedFilter }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Macro Budget Remaining card
                budgetCard

                // Filter chips
                filterChips

                // Suggestions
                ForEach(suggestions) { suggestion in
                    suggestionCard(suggestion)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(DesignTokens.Typography.icon(16))
                        Text("Back")
                            .font(DesignTokens.Typography.bodyFont(17))
                    }
                    .foregroundStyle(DesignTokens.Colors.fat)
                }
                .accessibilityLabel("Go back")
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    // MARK: - Budget Card

    private var budgetCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("🎯")
                .font(DesignTokens.Typography.icon(40))
                .padding(.top, DesignTokens.Spacing.md)

            Text("Macro Budget Remaining")
                .font(DesignTokens.Typography.semibold(18))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.lg) {
                budgetItem(value: "\(Int(remainingCalories))", label: "cal", color: DesignTokens.Colors.textPrimary)
                budgetItem(value: "\(Int(remainingProtein))g", label: "protein", color: DesignTokens.Colors.protein)
                budgetItem(value: "\(Int(remainingCarbs))g", label: "carbs", color: DesignTokens.Colors.carbs)
                budgetItem(value: "\(Int(remainingFat))g", label: "fat", color: DesignTokens.Colors.fat)
            }
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private func budgetItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(value)
                .font(DesignTokens.Typography.numeric(22))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            Text(label)
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(color)
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        withAnimation(DesignTokens.Anim.quick) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter)
                            .font(DesignTokens.Typography.medium(14))
                            .foregroundStyle(selectedFilter == filter ? DesignTokens.Colors.buttonPrimaryText : DesignTokens.Colors.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedFilter == filter ? DesignTokens.Colors.buttonPrimary : Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.clear : DesignTokens.Colors.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }

    // MARK: - Suggestion Card

    private func suggestionCard(_ item: FoodSuggestion) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                Text(item.emoji)
                    .font(DesignTokens.Typography.icon(36))

                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(item.name)
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(item.description)
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .lineLimit(2)
                }
            }

            // Macro chips + category
            HStack(spacing: DesignTokens.Spacing.xs) {
                macroChip("\(item.calories) cal", color: DesignTokens.Colors.textPrimary, bg: DesignTokens.Colors.textPrimary.opacity(0.08))
                macroChip("\(item.protein)g P", color: DesignTokens.Colors.protein, bg: DesignTokens.Colors.protein.opacity(0.08))
                macroChip("\(item.carbs)g C", color: DesignTokens.Colors.carbs, bg: DesignTokens.Colors.carbs.opacity(0.08))
                macroChip("\(item.fat)g F", color: DesignTokens.Colors.fat, bg: DesignTokens.Colors.fat.opacity(0.08))

                Spacer()

                Text(item.category)
                    .font(DesignTokens.Typography.medium(12))
                    .foregroundStyle(DesignTokens.Colors.brandAccent)
            }

            // Log This button
            Button {
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(DesignTokens.Typography.icon(16))
                    Text("Log This")
                        .font(DesignTokens.Typography.semibold(15))
                }
                .foregroundStyle(DesignTokens.Colors.brandAccent)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(DesignTokens.Colors.brandAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private func macroChip(_ text: String, color: Color, bg: Color) -> some View {
        Text(text)
            .font(DesignTokens.Typography.medium(12))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }
}
