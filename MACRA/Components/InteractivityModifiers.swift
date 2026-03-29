import SwiftUI

// MARK: - Pressable Button Style

/// Every tappable card and button should have a press effect.
/// Apply via `.pressable()` or `.buttonStyle(PressableButtonStyle())`.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.default, value: configuration.isPressed)
    }
}

// MARK: - Apple Button Style

/// Standard Apple-feel button style: dims opacity on press.
struct AppleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.default, value: configuration.isPressed)
    }
}

// MARK: - Numeric Text Modifier

/// Applies `.contentTransition(.numericText())` with a spring animation
/// keyed to the provided integer value.
struct NumericTransitionModifier: ViewModifier {
    let value: Int

    func body(content: Content) -> some View {
        content
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4), value: value)
    }
}

// MARK: - Ring Pulse Modifier

/// Pulses a ring with a subtle scale overshoot when the trigger value changes.
struct RingPulseModifier: ViewModifier {
    let trigger: Int
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isPulsing)
            .onChange(of: trigger) { _, _ in
                isPulsing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isPulsing = false
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a subtle opacity press effect for tappable elements.
    func pressable() -> some View {
        buttonStyle(PressableButtonStyle())
    }

    /// Adds `.contentTransition(.numericText())` animated by a spring keyed to the value.
    func numericTransition(value: Int) -> some View {
        modifier(NumericTransitionModifier(value: value))
    }

    /// Pulses the view with a brief scale overshoot when the trigger value changes.
    func ringPulse(trigger: Int) -> some View {
        modifier(RingPulseModifier(trigger: trigger))
    }
}
