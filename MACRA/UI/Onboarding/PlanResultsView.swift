import SwiftUI

struct PlanResultsView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var showRing = false

    private var totalMacroGrams: Double {
        Double(viewModel.calculatedProtein + viewModel.calculatedCarbs + viewModel.calculatedFat)
    }

    private var proteinFraction: Double {
        guard totalMacroGrams > 0 else { return 0.33 }
        return Double(viewModel.calculatedProtein) / totalMacroGrams
    }

    private var carbsFraction: Double {
        guard totalMacroGrams > 0 else { return 0.33 }
        return Double(viewModel.calculatedCarbs) / totalMacroGrams
    }

    private var fatFraction: Double {
        guard totalMacroGrams > 0 else { return 0.34 }
        return Double(viewModel.calculatedFat) / totalMacroGrams
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "Your personal plan")
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            // Macro ring
            ZStack {
                macroRing
                    .frame(width: 200, height: 200)

                // Center calories
                VStack(spacing: 2) {
                    Text("\(viewModel.calculatedCalories)")
                        .font(OnboardingTheme.largeNumberFont)
                        .tracking(OnboardingTheme.largeNumberTracking)
                        .foregroundStyle(OnboardingTheme.textPrimary)

                    Text("cal/day")
                        .font(QyraFont.medium(14))
                        .foregroundStyle(OnboardingTheme.textSecondary)
                }
            }

            // Legend
            HStack(spacing: DesignTokens.Spacing.lg) {
                macroLegendItem(
                    color: OnboardingTheme.macroProtein,
                    label: "Protein",
                    value: "\(viewModel.calculatedProtein)g"
                )
                macroLegendItem(
                    color: OnboardingTheme.macroCarbs,
                    label: "Carbs",
                    value: "\(viewModel.calculatedCarbs)g"
                )
                macroLegendItem(
                    color: OnboardingTheme.macroFat,
                    label: "Fat",
                    value: "\(viewModel.calculatedFat)g"
                )
            }
            .padding(.top, 28)

            Spacer()

            OnboardingContinueButton(label: "Continue") {
                viewModel.advance()
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.8)) {
                showRing = true
            }
        }
    }

    // MARK: - Macro Ring

    private var macroRing: some View {
        ZStack {
            // Fat arc (starts from protein + carbs end)
            Circle()
                .trim(
                    from: showRing ? CGFloat(proteinFraction + carbsFraction) : 0,
                    to: showRing ? 1.0 : 0
                )
                .stroke(OnboardingTheme.macroFat, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            // Carbs arc (starts from protein end)
            Circle()
                .trim(
                    from: showRing ? CGFloat(proteinFraction) : 0,
                    to: showRing ? CGFloat(proteinFraction + carbsFraction) : 0
                )
                .stroke(OnboardingTheme.macroCarbs, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                .rotationEffect(.degrees(-90))

            // Protein arc (starts from 0)
            Circle()
                .trim(from: 0, to: showRing ? CGFloat(proteinFraction) : 0)
                .stroke(OnboardingTheme.macroProtein, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                .rotationEffect(.degrees(-90))
        }
    }

    // MARK: - Legend Item

    private func macroLegendItem(color: Color, label: String, value: String) -> some View {
        VStack(spacing: DesignTokens.Layout.microGap) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(value)
                .font(QyraFont.bold(17))
                .foregroundStyle(OnboardingTheme.textPrimary)

            Text(label)
                .font(QyraFont.regular(13))
                .foregroundStyle(OnboardingTheme.textSecondary)
        }
    }
}

#Preview {
    PlanResultsView(viewModel: .preview)
}
