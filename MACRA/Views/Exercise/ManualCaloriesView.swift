import SwiftUI

struct ManualCaloriesView: View {
    @Bindable var viewModel: ExerciseViewModel

    @State private var caloriesText: String = ""
    @State private var navigateToResult = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Center content with ring and calorie input
            ZStack {
                // Decorative ring
                MacroRingView(
                    progress: caloriesText.isEmpty ? 0 : 0.75,
                    ringColor: DesignTokens.Colors.accent,
                    trackColor: DesignTokens.Colors.accent.opacity(0.2),
                    size: 200,
                    lineWidth: 10
                )

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(DesignTokens.Typography.icon(28))
                        .foregroundStyle(DesignTokens.Colors.accent)

                    TextField("0", text: $caloriesText)
                        .font(DesignTokens.Typography.numeric(48))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($isInputFocused)
                        .frame(width: 140)

                    Text("cal")
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Spacer()

            // Continue button pinned to bottom
            VStack {
                MonochromeButton("Continue", style: .primary) {
                    isInputFocused = false
                    viewModel.selectedType = .manual
                    viewModel.caloriesBurned = Double(caloriesText) ?? 0
                    navigateToResult = true
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Manual")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isInputFocused = true
        }
        .onTapGesture {
            isInputFocused = false
        }
        .navigationDestination(isPresented: $navigateToResult) {
            BurnedCaloriesResultView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        ManualCaloriesView(viewModel: ExerciseViewModel())
    }
}
