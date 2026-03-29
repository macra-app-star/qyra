import SwiftUI

struct ExerciseTypeView: View {
    @State private var viewModel = ExerciseViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showWorkoutSession = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.md) {
                    exerciseCard(
                        type: .run,
                        destination: ExerciseIntensityView(
                            exerciseType: .run,
                            viewModel: viewModel
                        )
                    )

                    // Weight Lifting → full session tracker (sheet)
                    Button {
                        showWorkoutSession = true
                    } label: {
                        exerciseCardLabel(type: .weightLifting)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    NavigationLink {
                        DescribeExerciseView(viewModel: viewModel)
                    } label: {
                        exerciseCardLabel(type: .describe)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    NavigationLink {
                        ManualCaloriesView(viewModel: viewModel)
                    } label: {
                        exerciseCardLabel(type: .manual)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Log exercise")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.configure(modelContainer: modelContext.container)
            }
            .onChange(of: viewModel.didSave) { _, saved in
                if saved {
                    dismiss()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(DesignTokens.Typography.icon(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                }
            }
        }
        .tint(.accentColor)
        .fullScreenCover(isPresented: $showWorkoutSession) {
            WorkoutSessionView()
        }
    }

    private func exerciseCard<D: View>(type: ExerciseType, destination: D) -> some View {
        NavigationLink {
            destination
        } label: {
            exerciseCardLabel(type: type)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func exerciseCardLabel(type: ExerciseType) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: type.iconName)
                .font(DesignTokens.Typography.icon(24))
                .foregroundStyle(DesignTokens.Colors.accent)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(type.displayName)
                    .font(DesignTokens.Typography.semibold(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(type.subtitle)
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.icon(14))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .frame(minHeight: 72)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

#Preview {
    ExerciseTypeView()
}
