import SwiftUI

struct OnboardingSubtitle: View {
    let text: String
    var alignment: TextAlignment = .leading

    var body: some View {
        Text(text)
            .font(OnboardingTheme.subtitleFont)
            .foregroundStyle(OnboardingTheme.textSecondary)
            .lineSpacing(6)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, alignment: alignment == .center ? .center : .leading)
            .padding(.horizontal, OnboardingTheme.screenPadding)
            .padding(.top, DesignTokens.Layout.tightGap)
    }
}

#Preview {
    VStack(spacing: DesignTokens.Layout.cardGap) {
        OnboardingSubtitle(text: "This will be used to calibrate your custom plan.")
        OnboardingSubtitle(text: "Center aligned subtitle", alignment: .center)
    }
}
