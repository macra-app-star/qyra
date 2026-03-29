import SwiftUI

struct PlanGenerationView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var animatedProgress: Double = 0
    @State private var displayPercentage: Int = 0
    @State private var currentStepIndex: Int = 0
    @State private var completedItems: Set<Int> = []

    private let stepMessages = [
        "Analyzing your profile...",
        "Applying BMR formula...",
        "Calculating macro split...",
        "Setting daily targets...",
        "Finalizing your plan..."
    ]

    private let checklistItems = [
        "Calories",
        "Carbs",
        "Protein",
        "Fats",
        "Health Score"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Percentage counter — clean monospaced digits
                Text("\(displayPercentage)%")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(OnboardingTheme.textPrimary)

                // Subtitle
                Text("We're setting everything\nup for you")
                    .font(QyraFont.bold(24))
                    .tracking(-0.5)
                    .foregroundStyle(OnboardingTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, DesignTokens.Layout.tightGap)

                // Progress bar — smooth gradient
                progressBar
                    .padding(.horizontal, OnboardingTheme.screenPadding)
                    .padding(.top, DesignTokens.Spacing.lg)

                // Status text
                Text(stepMessages[min(currentStepIndex, stepMessages.count - 1)])
                    .font(QyraFont.regular(15))
                    .foregroundStyle(OnboardingTheme.textSecondary)
                    .padding(.top, DesignTokens.Layout.itemGap)
                    .animation(.easeInOut(duration: 0.2), value: currentStepIndex)

                // Daily recommendation checklist
                VStack(alignment: .leading, spacing: DesignTokens.Layout.itemGap) {
                    Text("Daily recommendation for")
                        .font(QyraFont.bold(16))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .padding(.bottom, 2)

                    ForEach(Array(checklistItems.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 0) {
                            Text("•")
                                .font(QyraFont.regular(16))
                                .foregroundStyle(OnboardingTheme.textPrimary)
                                .frame(width: 16)

                            Text(item)
                                .font(QyraFont.regular(16))
                                .foregroundStyle(OnboardingTheme.textPrimary)

                            Spacer()

                            if completedItems.contains(index) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(QyraFont.regular(22))
                                    .foregroundStyle(OnboardingTheme.textPrimary)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
                .padding(.horizontal, OnboardingTheme.screenPadding)
                .padding(.top, DesignTokens.Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(OnboardingTheme.background)
        .task {
            await runSmoothGeneration()
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(OnboardingTheme.progressEmpty)
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignTokens.Colors.error,
                                .purple,
                                OnboardingTheme.accentBlue
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * animatedProgress, height: 8)
                    .animation(.linear(duration: 0.05), value: animatedProgress)
            }
        }
        .frame(height: 8)
    }

    // MARK: - Smooth Generation (Robinhood-style)

    private func runSmoothGeneration() async {
        // Start save in parallel
        async let saveTask: () = viewModel.savePlan()

        // Smooth animation over 4.5 seconds with cubic ease-in-out
        let totalDuration: Double = 4.5
        let fps: Double = 30.0
        let tickInterval: Double = 1.0 / fps
        let totalTicks = Int(totalDuration * fps)

        for tick in 0...totalTicks {
            let t = min(Double(tick) / Double(totalTicks), 1.0)

            // Cubic ease-in-out
            let eased: Double
            if t < 0.5 {
                eased = 4.0 * t * t * t
            } else {
                eased = 1.0 - pow(-2.0 * t + 2.0, 3) / 2.0
            }

            displayPercentage = Int(eased * 100)
            animatedProgress = eased
            currentStepIndex = min(Int(eased * Double(stepMessages.count)), stepMessages.count - 1)

            // Reveal checklist items progressively
            for i in 0..<checklistItems.count {
                if eased > Double(i + 1) / Double(checklistItems.count + 1) {
                    if !completedItems.contains(i) {
                        _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            completedItems.insert(i)
                        }
                    }
                }
            }

            try? await Task.sleep(for: .seconds(tickInterval))
        }

        // Final state
        displayPercentage = 100
        animatedProgress = 1.0
        withAnimation { completedItems = Set(0..<checklistItems.count) }

        // Ensure save is done
        await saveTask

        try? await Task.sleep(for: .milliseconds(600))

        DesignTokens.Haptics.success()
        viewModel.planGenerationComplete = true
        viewModel.advance()
    }
}

#Preview {
    PlanGenerationView(viewModel: .preview)
}
