import SwiftUI

// MARK: - Onboarding Transition Modifiers

extension View {
    func onboardingSlideTransition(edge: Edge = .trailing) -> some View {
        self.transition(.asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge == .trailing ? .leading : .trailing).combined(with: .opacity)
        ))
    }

    func onboardingFadeTransition() -> some View {
        self.transition(.opacity)
    }

    func onboardingShadow(_ shadow: OnboardingShadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: 0, y: shadow.y)
    }

    func onboardingCardStyle(isSelected: Bool = false) -> some View {
        self
            .padding(.horizontal, OnboardingTheme.cardPadding)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected ? OnboardingTheme.selectedCardBg : OnboardingTheme.backgroundSecondary
            )
            .clipShape(RoundedRectangle(cornerRadius: OnboardingTheme.cardCornerRadius))
            .animation(OnboardingTheme.quickSpring, value: isSelected)
    }
}

// MARK: - Press Opacity Effect

struct PressOpacityEffect: ViewModifier {
    let pressedOpacity: Double
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .opacity(isPressed ? pressedOpacity : 1.0)
            .animation(.default, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func pressScale(_ scale: CGFloat = 0.97) -> some View {
        modifier(PressOpacityEffect(pressedOpacity: 0.7))
    }
}
