import SwiftUI

struct OnboardingTitle: View {
    let text: String
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text)
            .font(OnboardingTheme.titleFont)
            .tracking(OnboardingTheme.titleTracking)
            .foregroundStyle(OnboardingTheme.textPrimary)
            .lineSpacing(4)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
            .padding(.horizontal, OnboardingTheme.screenPadding)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Layout.cardGap) {
        OnboardingTitle(text: "Choose your Gender")
        OnboardingTitle(text: "Nutrition intelligence made effortless", alignment: .center)
    }
}
