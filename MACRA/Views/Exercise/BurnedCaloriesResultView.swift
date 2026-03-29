import SwiftUI

struct BurnedCaloriesResultView: View {
    @Bindable var viewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var ringProgress: Double = 0
    @State private var isEditingCalories = false
    @State private var editText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Animated calorie ring
            MacroRingView(
                progress: ringProgress,
                ringColor: DesignTokens.Colors.accent,
                trackColor: DesignTokens.Colors.accent.opacity(0.2),
                size: 240,
                lineWidth: 14
            ) {
                calorieCenter
            }

            Spacer()

            // Log button pinned to bottom
            VStack {
                MonochromeButton("Log", style: .primary) {
                    DesignTokens.Haptics.success()
                    viewModel.logExercise()
                    dismissEntireFlow()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Burned Calories")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editText = "\(Int(viewModel.caloriesBurned))"
            withAnimation(DesignTokens.Anim.ring.delay(0.2)) {
                ringProgress = 1.0
            }
        }
    }

    // MARK: - Center Content

    @ViewBuilder
    private var calorieCenter: some View {
        if isEditingCalories {
            VStack(spacing: DesignTokens.Spacing.xs) {
                TextField("0", text: $editText)
                    .font(DesignTokens.Typography.numeric(36))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 120)
                    .onSubmit {
                        commitEdit()
                    }

                Text("cal")
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Button {
                    commitEdit()
                } label: {
                    Text("Done")
                        .font(DesignTokens.Typography.medium(14))
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
            }
        } else {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text("\(Int(viewModel.caloriesBurned))")
                    .font(DesignTokens.Typography.numeric(36))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .contentTransition(.numericText())

                Text("cal")
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
            .onTapGesture {
                editText = "\(Int(viewModel.caloriesBurned))"
                withAnimation(DesignTokens.Anim.quick) {
                    isEditingCalories = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func commitEdit() {
        let newValue = Double(editText) ?? viewModel.caloriesBurned
        withAnimation(DesignTokens.Anim.standard) {
            viewModel.caloriesBurned = newValue
            isEditingCalories = false
        }
    }

    private func dismissEntireFlow() {
        // Dismiss all the way back to root by popping to the presenting sheet
        // The sheet presentation will be dismissed from the parent
        dismiss()
    }
}

#Preview {
    NavigationStack {
        BurnedCaloriesResultView(viewModel: {
            let vm = ExerciseViewModel()
            vm.caloriesBurned = 342
            return vm
        }())
    }
}
