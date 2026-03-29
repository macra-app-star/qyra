import SwiftUI

struct DesiredWeightView: View {
    @Bindable var viewModel: OnboardingViewModel

    private var weightBinding: Binding<Int> {
        if viewModel.useMetric {
            return Binding(
                get: { Int(viewModel.desiredWeightKg) },
                set: { viewModel.desiredWeightKg = Double($0) }
            )
        } else {
            return Binding(
                get: { Int(viewModel.desiredWeightLbs) },
                set: { viewModel.desiredWeightLbs = Double($0) }
            )
        }
    }

    private var weightUnit: String {
        viewModel.useMetric ? "kg" : "lbs"
    }

    private var currentWeight: Double {
        viewModel.useMetric ? viewModel.desiredWeightKg : viewModel.desiredWeightLbs
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTitle(text: "What is your desired weight?")
                .padding(.top, DesignTokens.Spacing.lg)

            Spacer()

            VStack(spacing: DesignTokens.Spacing.md) {
                // Goal label
                Text(viewModel.goalType.onboardingLabel)
                    .font(QyraFont.regular(14))
                    .foregroundStyle(OnboardingTheme.textSecondary)

                // Weight display
                HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Layout.microGap) {
                    Text("\(Int(currentWeight))")
                        .font(QyraFont.bold(56))
                        .tracking(-2)
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: currentWeight)

                    Text(weightUnit)
                        .font(QyraFont.medium(24))
                        .foregroundStyle(OnboardingTheme.textSecondary)
                }

                // Unit toggle
                HStack(spacing: DesignTokens.Layout.cardGap) {
                    Text("lbs")
                        .font(viewModel.useMetric ? QyraFont.regular(15) : QyraFont.bold(15))
                        .foregroundStyle(viewModel.useMetric ? OnboardingTheme.textSecondary : OnboardingTheme.textPrimary)

                    Toggle("", isOn: $viewModel.useMetric)
                        .labelsHidden()
                        .tint(OnboardingTheme.selectedCardBg)

                    Text("kg")
                        .font(viewModel.useMetric ? QyraFont.bold(15) : QyraFont.regular(15))
                        .foregroundStyle(viewModel.useMetric ? OnboardingTheme.textPrimary : OnboardingTheme.textSecondary)
                }

                // Picker wheel
                Picker("Weight", selection: weightBinding) {
                    if viewModel.useMetric {
                        ForEach(30...200, id: \.self) { kg in
                            Text("\(kg) kg").tag(kg)
                        }
                    } else {
                        ForEach(66...400, id: \.self) { lb in
                            Text("\(lb) lbs").tag(lb)
                        }
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150)
                .clipped()
                .padding(.horizontal, OnboardingTheme.screenPadding)
            }

            Spacer()

            OnboardingContinueButton(isEnabled: true) {
                viewModel.advance()
            }
        }
        .animation(OnboardingTheme.defaultSpring, value: viewModel.useMetric)
    }
}

#Preview {
    DesiredWeightView(viewModel: .preview)
}
