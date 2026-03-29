import SwiftUI

struct ExerciseIntensityView: View {
    let exerciseType: ExerciseType
    @Bindable var viewModel: ExerciseViewModel
    @Environment(\.dismiss) private var dismiss

    private let durationOptions = [15, 30, 45, 60, 90]

    @State private var navigateToResult = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Intensity selector
                    intensitySection

                    // Duration pills
                    durationSection
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.xxl)
            }

            // Continue button pinned to bottom
            VStack {
                MonochromeButton("Continue", style: .primary) {
                    viewModel.selectedType = exerciseType
                    viewModel.calculateCalories()
                    navigateToResult = true
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle(exerciseType.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToResult) {
            BurnedCaloriesResultView(viewModel: viewModel)
        }
    }

    // MARK: - Intensity Section

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Intensity")
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(exerciseType.intensityLevels.enumerated()), id: \.element.id) { index, level in
                    intensityRow(level: level, levelIndex: index + 1)
                }
            }
        }
    }

    private func intensityRow(level: IntensityLevel, levelIndex: Int) -> some View {
        let isSelected = viewModel.intensity == levelIndex

        return Button {
            withAnimation(DesignTokens.Anim.quick) {
                viewModel.intensity = levelIndex
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                    Text(level.name)
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(isSelected ? .white : DesignTokens.Colors.textPrimary)

                    Text(level.description)
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : DesignTokens.Colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(DesignTokens.Typography.icon(16))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(isSelected ? Color.accentColor : DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Duration")
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(durationOptions, id: \.self) { minutes in
                        durationPill(minutes: minutes)
                    }
                }
            }
        }
    }

    private func durationPill(minutes: Int) -> some View {
        let isSelected = viewModel.durationMinutes == minutes

        return Button {
            withAnimation(DesignTokens.Anim.quick) {
                viewModel.durationMinutes = minutes
            }
        } label: {
            Text("\(minutes) min")
                .font(DesignTokens.Typography.medium(14))
                .foregroundStyle(isSelected ? DesignTokens.Colors.selectedPillText : DesignTokens.Colors.unselectedPillText)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(isSelected ? DesignTokens.Colors.selectedPillBg : DesignTokens.Colors.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        ExerciseIntensityView(
            exerciseType: .run,
            viewModel: ExerciseViewModel()
        )
    }
}
