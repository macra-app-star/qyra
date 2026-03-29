import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exercises: [SessionExercise] = []
    @State private var sessionStart = Date()
    @State private var showExercisePicker = false
    @State private var showSummary = false
    @State private var restTimerSeconds: Int = 0
    @State private var restTimerActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Session timer header
                sessionHeader

                // Exercise list
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.lg) {
                        ForEach($exercises) { $exercise in
                            exerciseSection(exercise: $exercise)
                        }

                        // Add exercise button
                        Button {
                            showExercisePicker = true
                        } label: {
                            Label("Add Exercise", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                    }
                    .padding(.top, DesignTokens.Spacing.md)
                    .padding(.bottom, 100)
                }

                // Finish button
                Button {
                    showSummary = true
                } label: {
                    Text("Finish Workout")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(exercises.isEmpty)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.md)
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                NavigationStack {
                    ExerciseSearchView(onAddToWorkout: { exercise in
                        // Add exercise to session
                        let entry = SessionExercise(
                            name: exercise.name,
                            sets: [
                                WorkoutSetEntry(setNumber: 1, weight: 0, reps: 10)
                            ]
                        )
                        exercises.append(entry)
                        showExercisePicker = false
                    })
                }
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showSummary) {
                workoutSummary
            }
        }
    }

    // MARK: - Session Header

    private var sessionHeader: some View {
        HStack {
            // Timer
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .foregroundStyle(.secondary)
                Text(sessionDuration)
                    .font(.subheadline.weight(.medium).monospacedDigit())
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            Spacer()

            // Rest timer
            if restTimerActive {
                HStack(spacing: 6) {
                    Text("Rest")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(restTimerSeconds)s")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            // Exercise count
            Text("\(exercises.count) \(exercises.count == 1 ? "exercise" : "exercises")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Exercise Section

    private func exerciseSection(exercise: Binding<SessionExercise>) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Exercise name
            Text(exercise.wrappedValue.name)
                .font(.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)

            // Sets
            ForEach(exercise.sets) { $set in
                setRow(set: $set)
            }

            // Add set
            Button {
                let newSet = WorkoutSetEntry(
                    setNumber: exercise.wrappedValue.sets.count + 1,
                    weight: exercise.wrappedValue.sets.last?.weight ?? 0,
                    reps: exercise.wrappedValue.sets.last?.reps ?? 10
                )
                exercise.wrappedValue.sets.append(newSet)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }

    private func setRow(set: Binding<WorkoutSetEntry>) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Set number
            Text("Set \(set.wrappedValue.setNumber)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 50)

            // Weight
            HStack(spacing: 4) {
                TextField("0", value: set.weight, format: .number)
                    .font(.body.weight(.semibold))
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                Text("lbs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("×")
                .foregroundStyle(.secondary)

            // Reps
            HStack(spacing: 4) {
                TextField("0", value: set.reps, format: .number)
                    .font(.body.weight(.semibold))
                    .keyboardType(.numberPad)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                    .padding(8)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                Text("reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Complete checkbox
            Button {
                DesignTokens.Haptics.selection()
                set.wrappedValue.isCompleted.toggle()
            } label: {
                Image(systemName: set.wrappedValue.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.wrappedValue.isCompleted ? .green : .secondary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - Summary

    private var workoutSummary: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.title2.weight(.bold))

            VStack(spacing: DesignTokens.Spacing.sm) {
                summaryRow("Duration", value: sessionDuration)
                summaryRow("Exercises", value: "\(exercises.count)")
                summaryRow("Total Sets", value: "\(exercises.flatMap(\.sets).filter(\.isCompleted).count)")
                summaryRow("Est. Calories", value: "\(estimatedCalories) cal")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button {
                DesignTokens.Haptics.success()
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.lg)
        }
    }

    private func summaryRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
        }
    }

    // MARK: - Computed

    private var sessionDuration: String {
        let elapsed = Int(Date().timeIntervalSince(sessionStart))
        let mins = elapsed / 60
        let secs = elapsed % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var estimatedCalories: Int {
        let completedSets = exercises.flatMap(\.sets).filter(\.isCompleted)
        let setTuples = completedSets.map { (weight: $0.weight, reps: $0.reps, isLbs: true) }
        let totalVolume = WorkoutCalorieCalculator.totalVolumeKg(from: setTuples)
        let durationSeconds = Int(Date().timeIntervalSince(sessionStart))
        return WorkoutCalorieCalculator.estimate(totalVolumeKg: totalVolume, durationSeconds: durationSeconds)
    }
}

// MARK: - Workout Calorie Calculator

struct WorkoutCalorieCalculator {
    /// MET-based calorie estimation from total volume, duration, and body weight.
    static func estimate(totalVolumeKg: Double, durationSeconds: Int, bodyWeightKg: Double = 70.0) -> Int {
        let durationHours = max(Double(durationSeconds) / 3600.0, 1.0 / 60.0)
        let met: Double
        switch totalVolumeKg {
        case ..<500:      met = 3.5
        case 500..<2000:  met = 5.0
        case 2000..<5000: met = 6.0
        default:          met = 8.0
        }
        return max(Int((met * bodyWeightKg * durationHours).rounded()), 1)
    }

    /// Compute total volume in kg from a set of (weight, reps, isLbs) tuples.
    static func totalVolumeKg(from sets: [(weight: Double, reps: Int, isLbs: Bool)]) -> Double {
        sets.reduce(0.0) { total, set in
            let weightKg = set.isLbs ? set.weight * 0.453592 : set.weight
            return total + weightKg * Double(set.reps)
        }
    }
}

// MARK: - Models

struct SessionExercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: [WorkoutSetEntry]
}

struct WorkoutSetEntry: Identifiable {
    let id = UUID()
    var setNumber: Int
    var weight: Double
    var reps: Int
    var isCompleted: Bool = false
}

#Preview {
    WorkoutSessionView()
}
