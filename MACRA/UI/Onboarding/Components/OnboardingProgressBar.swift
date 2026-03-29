import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    init(currentStep: Int, totalSteps: Int = 16) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
    }

    var body: some View {
        HStack(spacing: OnboardingTheme.progressBarSpacing) {
            ForEach(0..<totalSteps, id: \.self) { index in
                RoundedRectangle(cornerRadius: OnboardingTheme.progressBarHeight / 2)
                    .fill(index < currentStep ? OnboardingTheme.progressFilled : OnboardingTheme.progressEmpty)
                    .frame(height: OnboardingTheme.progressBarHeight)
            }
        }
        .padding(.horizontal, OnboardingTheme.screenPadding)
        .animation(OnboardingTheme.quickSpring, value: currentStep)
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressBar(currentStep: 1)
        OnboardingProgressBar(currentStep: 8)
        OnboardingProgressBar(currentStep: 16)
    }
    .padding()
}
