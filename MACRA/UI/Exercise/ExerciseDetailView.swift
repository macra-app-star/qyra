import SwiftUI

// INTEGRATED FROM: ExerciseDB
// Detailed exercise view with instructions, muscle targeting, and log action.

struct ExerciseDetailView: View {
    let exercise: Exercise
    let onLog: ((Exercise) -> Void)?
    let onAddToWorkout: ((Exercise) -> Void)?

    @Environment(\.dismiss) private var dismiss

    init(exercise: Exercise, onLog: ((Exercise) -> Void)? = nil, onAddToWorkout: ((Exercise) -> Void)? = nil) {
        self.exercise = exercise
        self.onLog = onLog
        self.onAddToWorkout = onAddToWorkout
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {

                    // Header card
                    VStack(spacing: DesignTokens.Layout.itemGap) {
                        Image(systemName: iconForBodyPart(exercise.bodyPart))
                            .font(.system(size: 48, weight: .light))
                            .foregroundStyle(DesignTokens.Colors.tint)

                        Text(exercise.name.capitalized)
                            .font(QyraFont.bold(24))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignTokens.Spacing.xl)

                    // Muscle targeting
                    infoSection("Target") {
                        infoPill(exercise.targetMuscle.capitalized)
                    }

                    if !exercise.secondaryMuscles.isEmpty {
                        infoSection("Secondary Muscles") {
                            ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                                infoPill(muscle.capitalized)
                            }
                        }
                    }

                    infoSection("Equipment") {
                        infoPill(exercise.equipment.capitalized)
                    }

                    infoSection("Body Part") {
                        infoPill(exercise.bodyPart.capitalized)
                    }

                    // Instructions
                    if !exercise.instructions.isEmpty {
                        VStack(alignment: .leading, spacing: DesignTokens.Layout.itemGap) {
                            Text("Instructions")
                                .font(QyraFont.bold(17))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)

                            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: DesignTokens.Layout.itemGap) {
                                    Text("\(index + 1)")
                                        .font(QyraFont.bold(14))
                                        .foregroundStyle(DesignTokens.Colors.tint)
                                        .frame(width: 24, height: 24)
                                        .background(DesignTokens.Colors.tint.opacity(0.12))
                                        .clipShape(Circle())

                                    Text(instruction)
                                        .font(QyraFont.regular(15))
                                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }

                    // MET info
                    HStack {
                        Text("MET Value")
                            .font(QyraFont.medium(14))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text(String(format: "%.1f", exercise.metValue))
                            .font(QyraFont.bold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                    .padding()
                    .background(DesignTokens.Colors.neutral90)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .padding(.horizontal, DesignTokens.Layout.screenMargin)
                .padding(.bottom, 100) // Space for button
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    if let onAddToWorkout {
                        Button {
                            DesignTokens.Haptics.medium()
                            onAddToWorkout(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add to Workout")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.Layout.buttonHeight)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    if onLog != nil && onAddToWorkout == nil {
                        Button {
                            DesignTokens.Haptics.medium()
                            onLog?(exercise)
                            dismiss()
                        } label: {
                            Text("Log this exercise")
                                .font(QyraFont.semibold(17))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DesignTokens.Layout.buttonHeight)
                                .background(Color.accentColor)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Layout.screenMargin)
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
        }
    }

    // MARK: - Components

    private func infoSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(QyraFont.medium(13))
                .foregroundStyle(DesignTokens.Colors.textTertiary)

            FlowLayout(spacing: DesignTokens.Spacing.sm) {
                content()
            }
        }
    }

    private func infoPill(_ text: String) -> some View {
        Text(text)
            .font(QyraFont.medium(14))
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(DesignTokens.Colors.neutral90)
            .clipShape(Capsule())
    }

    private func iconForBodyPart(_ bodyPart: String) -> String {
        BodyPartCategory(rawValue: bodyPart)?.icon ?? "figure.strengthtraining.traditional"
    }
}

#Preview {
    ExerciseDetailView(
        exercise: Exercise(
            externalId: "preview",
            name: "Barbell Bench Press",
            bodyPart: "chest",
            targetMuscle: "pectorals",
            secondaryMuscles: ["anterior deltoids", "triceps"],
            equipment: "barbell",
            instructions: [
                "Lie on a flat bench with your feet on the floor.",
                "Grip the bar slightly wider than shoulder width.",
                "Lower the bar to your mid-chest.",
                "Press the bar back up to the starting position."
            ],
            metValue: 6.0
        )
    )
}
