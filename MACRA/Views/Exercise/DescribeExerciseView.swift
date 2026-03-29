import SwiftUI

struct DescribeExerciseView: View {
    @Bindable var viewModel: ExerciseViewModel

    @State private var navigateToResult = false
    @FocusState private var isTextEditorFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Text editor area
                    ZStack(alignment: .topLeading) {
                        if viewModel.exerciseDescription.isEmpty {
                            Text("Describe your exercise...")
                                .font(DesignTokens.Typography.bodyFont(16))
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                                .padding(.horizontal, DesignTokens.Spacing.xs)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                        }

                        TextEditor(text: $viewModel.exerciseDescription)
                            .font(DesignTokens.Typography.bodyFont(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                            .scrollContentBackground(.hidden)
                            .focused($isTextEditorFocused)
                    }
                    .frame(minHeight: 120)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                    // Example suggestions
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Examples:")
                            .font(DesignTokens.Typography.medium(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)

                        ForEach([
                            "45 minutes of basketball",
                            "Ran for 30 minutes",
                            "1 hour hiking",
                            "20 min jump rope"
                        ], id: \.self) { example in
                            Button {
                                viewModel.exerciseDescription = example
                            } label: {
                                Text(example)
                                    .font(DesignTokens.Typography.bodyFont(14))
                                    .foregroundStyle(DesignTokens.Colors.accent)
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                    // Smart parsing badge
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "bolt.fill")
                            .font(DesignTokens.Typography.icon(14))

                        Text("Smart parsing with MET calculations")
                            .font(DesignTokens.Typography.medium(13))
                    }
                    .foregroundStyle(DesignTokens.Colors.accent)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(DesignTokens.Colors.accent.opacity(0.12))
                    )
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                isTextEditorFocused = false
            }

            // Continue button pinned to bottom
            VStack {
                MonochromeButton("Continue", style: .primary) {
                    isTextEditorFocused = false
                    viewModel.selectedType = .describe
                    Task {
                        await viewModel.estimateFromDescription()
                        navigateToResult = true
                    }
                }
                .disabled(viewModel.isEstimating)
                .overlay {
                    if viewModel.isEstimating {
                        ProgressView()
                            .tint(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Describe")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            BurnedCaloriesResultView(viewModel: viewModel)
        }
    }
}

#Preview {
    NavigationStack {
        DescribeExerciseView(viewModel: ExerciseViewModel())
    }
}
