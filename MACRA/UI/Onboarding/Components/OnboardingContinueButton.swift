import SwiftUI

struct OnboardingContinueButton: View {
    let label: String
    let isEnabled: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        label: String = "Continue",
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            DesignTokens.Haptics.medium()
            action()
        }) {
            Text(label)
                .font(OnboardingTheme.buttonFont)
                .foregroundStyle(
                    isEnabled
                        ? OnboardingTheme.selectedCardText
                        : OnboardingTheme.selectedCardText.opacity(0.7)
                )
                .frame(maxWidth: .infinity)
                .frame(height: OnboardingTheme.buttonHeight)
                .background(
                    isEnabled
                        ? OnboardingTheme.selectedCardBg
                        : OnboardingTheme.buttonDisabledBg
                )
                .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.buttonCornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isPressed && isEnabled ? 0.7 : 1.0)
        .animation(.default, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if isEnabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
        .padding(.horizontal, OnboardingTheme.screenPadding)
        .padding(.bottom, DesignTokens.Layout.sectionGap)
        .padding(.top, DesignTokens.Layout.itemGap)
    }
}

#Preview {
    VStack {
        Spacer()
        OnboardingContinueButton(isEnabled: true) { }
        OnboardingContinueButton(label: "Get Started", isEnabled: false) { }
    }
}
