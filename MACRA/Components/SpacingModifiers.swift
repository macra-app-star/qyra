import SwiftUI

// MARK: - Screen Padding

struct ScreenPaddingModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.Layout.screenMargin)
    }
}

// MARK: - Card Style

struct CardStyleModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(DesignTokens.Layout.cardInternalPadding)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Primary CTA

struct PrimaryCTAModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(height: DesignTokens.Layout.buttonHeight)
            .frame(maxWidth: DesignTokens.Layout.buttonWidth)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.buttonPrimary)
            )
            .clipShape(Capsule())
    }
}

// MARK: - Section Header

struct SectionHeaderModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(QyraFont.semibold(16))
            .foregroundStyle(DesignTokens.Colors.textSecondary)
            .padding(.horizontal, DesignTokens.Layout.sectionHorizontalPadding)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies standard screen-level horizontal padding (20pt).
    func screenPadding() -> some View {
        modifier(ScreenPaddingModifier())
    }

    /// Applies card styling: internal padding, rounded background, and shadow.
    func cardStyle(cornerRadius: CGFloat = DesignTokens.Layout.cardCornerRadius) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius))
    }

    /// Applies primary CTA button styling: fixed height, max width, capsule shape.
    func primaryCTA() -> some View {
        modifier(PrimaryCTAModifier())
    }

    /// Applies section header text styling with horizontal padding.
    func sectionHeader() -> some View {
        modifier(SectionHeaderModifier())
    }

    /// Ensures the view meets the minimum tap target size (44pt).
    func minTapTarget() -> some View {
        frame(minWidth: DesignTokens.Layout.minTapTarget, minHeight: DesignTokens.Layout.minTapTarget)
    }
}
