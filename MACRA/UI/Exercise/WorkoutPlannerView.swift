import SwiftUI

// INTEGRATED FROM: ExerciseDB + Gemini AI
// AI-generated workout plans based on user goals and available equipment.

struct WorkoutPlannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WorkoutPlanViewModel()

    @State private var showPaywall = false
    @State private var isSubscribed = false

    var body: some View {
        NavigationStack {
            if !isSubscribed {
                PremiumGateView(
                    featureName: "Workout Planner",
                    icon: "figure.run",
                    showPaywall: $showPaywall
                )
                .sheet(isPresented: $showPaywall) {
                    OnboardingPaywallView(viewModel: OnboardingViewModel.preview)
                }
                .task {
                    isSubscribed = await SubscriptionService.shared.isSubscribed
                    #if DEBUG
                    if UserDefaults.standard.bool(forKey: "devBypassSubscription") { isSubscribed = true }
                    #endif
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("devSubscriptionBypassed"))) { _ in
                    isSubscribed = true
                }
            } else {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    if viewModel.generatedPlan == nil {
                        // Goal selection
                        goalSection
                        equipmentSection
                        generateButton
                    } else {
                        // Show plan
                        planView
                    }
                }
                .padding(.horizontal, DesignTokens.Layout.screenMargin)
                .padding(.vertical, DesignTokens.Spacing.lg)
            }
            .navigationTitle("Workout Planner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if viewModel.generatedPlan != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button("New Plan") {
                            viewModel.reset()
                        }
                    }
                }
            }
            } // else isSubscribed
        }
        .task {
            isSubscribed = await SubscriptionService.shared.isSubscribed
        }
    }

    // MARK: - Goal Selection

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Layout.itemGap) {
            Text("What's your goal?")
                .font(QyraFont.bold(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ForEach(WorkoutGoal.allCases) { goal in
                Button {
                    DesignTokens.Haptics.selection()
                    viewModel.selectedGoal = goal
                } label: {
                    HStack(spacing: DesignTokens.Layout.itemGap) {
                        Image(systemName: goal.icon)
                            .font(.system(size: 20))
                            .foregroundStyle(viewModel.selectedGoal == goal ? .white : DesignTokens.Colors.tint)
                            .frame(width: 40, height: 40)
                            .background(viewModel.selectedGoal == goal ? DesignTokens.Colors.tint : DesignTokens.Colors.tint.opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.displayName)
                                .font(QyraFont.semibold(16))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                            Text(goal.subtitle)
                                .font(QyraFont.regular(13))
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }

                        Spacer()

                        if viewModel.selectedGoal == goal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DesignTokens.Colors.tint)
                        }
                    }
                    .padding()
                    .background(DesignTokens.Colors.neutral90)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Layout.itemGap) {
            Text("Available equipment")
                .font(QyraFont.bold(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(EquipmentOption.allCases) { equipment in
                    Button {
                        DesignTokens.Haptics.selection()
                        viewModel.toggleEquipment(equipment)
                    } label: {
                        Text(equipment.displayName)
                            .font(QyraFont.medium(14))
                            .foregroundStyle(
                                viewModel.selectedEquipment.contains(equipment)
                                    ? .white : DesignTokens.Colors.textPrimary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedEquipment.contains(equipment)
                                    ? Color.accentColor : DesignTokens.Colors.neutral90
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button {
            DesignTokens.Haptics.medium()
            Task { await viewModel.generatePlan() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(viewModel.isGenerating ? "Generating..." : "Generate workout")
            }
            .font(QyraFont.semibold(17))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.Layout.buttonHeight)
            .background(DesignTokens.Colors.tint)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isGenerating || viewModel.selectedGoal == nil)
        .opacity(viewModel.selectedGoal == nil ? 0.5 : 1)
        .padding(.top, DesignTokens.Spacing.lg)
    }

    // MARK: - Plan View

    private var planView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            if let plan = viewModel.generatedPlan {
                Text(plan.title)
                    .font(QyraFont.bold(24))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(plan.description)
                    .font(QyraFont.regular(15))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                ForEach(Array(plan.exercises.enumerated()), id: \.offset) { index, exercise in
                    HStack(spacing: DesignTokens.Layout.itemGap) {
                        Text("\(index + 1)")
                            .font(QyraFont.bold(14))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(DesignTokens.Colors.tint)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(QyraFont.semibold(16))
                                .foregroundStyle(DesignTokens.Colors.textPrimary)
                            Text(exercise.detail)
                                .font(QyraFont.regular(14))
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(DesignTokens.Colors.neutral90)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
            }
        }
    }
}

// MARK: - ViewModel

@Observable @MainActor
final class WorkoutPlanViewModel {
    var selectedGoal: WorkoutGoal?
    var selectedEquipment: Set<EquipmentOption> = [.bodyweight]
    var isGenerating = false
    var generatedPlan: WorkoutPlan?

    func toggleEquipment(_ equipment: EquipmentOption) {
        if selectedEquipment.contains(equipment) {
            selectedEquipment.remove(equipment)
        } else {
            selectedEquipment.insert(equipment)
        }
    }

    func generatePlan() async {
        guard let goal = selectedGoal else { return }
        isGenerating = true

        let equipment = selectedEquipment.map(\.displayName).joined(separator: ", ")
        let prompt = """
        Generate a workout plan for goal: \(goal.displayName).
        Available equipment: \(equipment).
        Return a JSON object: { "title": string, "description": string, "exercises": [{ "name": string, "detail": string }] }
        Include 6-8 exercises. Detail should include sets x reps or duration.
        """

        do {
            let response = try await GeminiService.shared.chat(
                userMessage: prompt,
                systemContext: "You are a certified personal trainer. Generate concise workout plans as JSON."
            )

            // Parse JSON from response
            let cleaned = response
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let data = cleaned.data(using: .utf8) {
                generatedPlan = try JSONDecoder().decode(WorkoutPlan.self, from: data)
            }
        } catch {
            // Fallback plan
            generatedPlan = WorkoutPlan.fallback(for: goal)
        }

        isGenerating = false
    }

    func reset() {
        generatedPlan = nil
        selectedGoal = nil
        selectedEquipment = [.bodyweight]
    }
}

// MARK: - Models

enum WorkoutGoal: String, CaseIterable, Identifiable {
    case strength, hypertrophy, endurance, fatLoss

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .hypertrophy: return "Muscle Growth"
        case .endurance: return "Endurance"
        case .fatLoss: return "Fat Loss"
        }
    }

    var subtitle: String {
        switch self {
        case .strength: return "Heavy weight, low reps"
        case .hypertrophy: return "Moderate weight, high volume"
        case .endurance: return "Light weight, high reps"
        case .fatLoss: return "Circuit training, HIIT"
        }
    }

    var icon: String {
        switch self {
        case .strength: return "bolt.fill"
        case .hypertrophy: return "dumbbell.fill"
        case .endurance: return "timer"
        case .fatLoss: return "flame.fill"
        }
    }
}

enum EquipmentOption: String, CaseIterable, Identifiable, Hashable {
    case bodyweight, dumbbells, barbell, kettlebell, resistanceBands, machine, pullUpBar

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bodyweight: return "Body weight"
        case .dumbbells: return "Dumbbells"
        case .barbell: return "Barbell"
        case .kettlebell: return "Kettlebell"
        case .resistanceBands: return "Bands"
        case .machine: return "Machines"
        case .pullUpBar: return "Pull-up bar"
        }
    }
}

struct WorkoutPlan: Codable {
    let title: String
    let description: String
    let exercises: [WorkoutExercise]

    static func fallback(for goal: WorkoutGoal) -> WorkoutPlan {
        WorkoutPlan(
            title: "\(goal.displayName) Workout",
            description: "A balanced \(goal.displayName.lowercased()) workout.",
            exercises: [
                WorkoutExercise(name: "Warm-up", detail: "5 minutes light cardio"),
                WorkoutExercise(name: "Push-ups", detail: "3 x 12 reps"),
                WorkoutExercise(name: "Squats", detail: "3 x 15 reps"),
                WorkoutExercise(name: "Plank", detail: "3 x 30 seconds"),
                WorkoutExercise(name: "Lunges", detail: "3 x 12 each leg"),
                WorkoutExercise(name: "Cool-down", detail: "5 minutes stretching"),
            ]
        )
    }
}

struct WorkoutExercise: Codable {
    let name: String
    let detail: String
}

#Preview {
    WorkoutPlannerView()
}
