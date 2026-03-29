import SwiftUI

struct OnboardingBackButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            DesignTokens.Haptics.light()
            action()
        }) {
            Image(systemName: "chevron.left")
                .font(QyraFont.medium(16))
                .foregroundStyle(.secondary)
                .frame(
                    width: OnboardingTheme.backButtonSize,
                    height: OnboardingTheme.backButtonSize
                )
                .background(isPressed ? OnboardingTheme.backgroundTertiary : OnboardingTheme.backgroundSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .opacity(isPressed ? 0.7 : 1.0)
        .animation(.default, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, OnboardingTheme.screenPadding)
        .padding(.top, DesignTokens.Layout.cardGap)
    }
}

#Preview {
    OnboardingBackButton { }
}
