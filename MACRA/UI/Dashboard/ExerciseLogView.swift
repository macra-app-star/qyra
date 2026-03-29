import SwiftUI

struct ExerciseLogView: View {
    @State private var searchText = ""
    @State private var exerciseName = ""
    @State private var selectedType = "Cardio"
    @State private var duration = ""
    @State private var caloriesBurned = ""
    @Environment(\.dismiss) private var dismiss

    private let exerciseTypes = ["Cardio", "Strength", "Flexibility"]

    private let quickSelectItems: [(name: String, icon: String, cal: Int)] = [
        ("Walking", "figure.walk", 150),
        ("Running", "figure.run", 350),
        ("Cycling", "figure.outdoor.cycle", 280),
        ("Weights", "dumbbell.fill", 200),
        ("Swimming", "figure.pool.swim", 300),
        ("Yoga", "figure.mind.and.body", 120),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Search
                searchField

                // Quick Select
                quickSelectSection

                // Manual entry form
                manualEntryForm

                // Log button
                logButton

                // Today's Exercise
                todaySection
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DesignTokens.Colors.background)
        .navigationTitle("Log Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(DesignTokens.Typography.icon(16))
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            TextField("Search Activity Database", text: $searchText)
                .font(DesignTokens.Typography.bodyFont(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Quick Select

    private var quickSelectSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Quick Select")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(quickSelectItems, id: \.name) { item in
                        Button {
                            exerciseName = item.name
                            caloriesBurned = "\(item.cal)"
                            duration = "30"
                        } label: {
                            VStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: item.icon)
                                    .font(DesignTokens.Typography.icon(24))
                                    .foregroundStyle(DesignTokens.Colors.protein)
                                Text(item.name)
                                    .font(DesignTokens.Typography.medium(12))
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                            }
                            .frame(width: 80)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .background(DesignTokens.Colors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Manual Entry

    private var manualEntryForm: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Exercise Name
            formField(label: "Exercise Name", placeholder: "e.g. Morning Run", text: $exerciseName)

            // Type selector
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Type")
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Picker("Type", selection: $selectedType) {
                    ForEach(exerciseTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Duration + Calories
            HStack(spacing: DesignTokens.Spacing.md) {
                formField(label: "Duration (min)", placeholder: "30", text: $duration)
                formField(label: "Calories Burned", placeholder: "200", text: $caloriesBurned)
            }
        }
    }

    private func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(label)
                .font(DesignTokens.Typography.medium(14))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            TextField(placeholder, text: text)
                .font(DesignTokens.Typography.bodyFont(16))
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Log Button

    private var logButton: some View {
        Button {
            DesignTokens.Haptics.success()
            dismiss()
        } label: {
            Text("Log Exercise")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(DesignTokens.Colors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Today's Exercise

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Today's Exercise")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            EmptyDataView(
                title: "No Exercises Logged",
                subtitle: "Use quick select or fill in the form above."
            )
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }
}
