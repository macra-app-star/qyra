import SwiftUI

// MARK: - OnboardingTheme
// Thin alias layer over DesignTokens — keeps onboarding views compiling
// while pointing every color to the single source of truth.

enum OnboardingTheme {
    // MARK: - Colors (aliases → DesignTokens)

    // Backgrounds
    static let background       = DesignTokens.Colors.neutral100
    static let backgroundSecondary = DesignTokens.Colors.neutral90
    static let backgroundTertiary  = DesignTokens.Colors.neutral80

    // Text
    static let textPrimary   = DesignTokens.Colors.textPrimary
    static let textSecondary = DesignTokens.Colors.textSecondary
    static let textTertiary  = DesignTokens.Colors.textTertiary

    // Accent colors
    static let accent      = Color(hex: "E4A472")              // Warm peach/tan — onboarding brand
    static let accentRed   = DesignTokens.Colors.error
    static let accentGreen = DesignTokens.Colors.success
    static let accentBlue  = DesignTokens.Colors.fat

    // Selected card — Apple blue accent
    static let selectedCardBg   = Color.accentColor
    static let selectedCardText = Color.white

    // Progress bar
    static let progressFilled = Color.accentColor
    static let progressEmpty  = Color(.systemGray5)

    // Divider
    static let divider = DesignTokens.Colors.separator

    // Disabled button
    static let buttonDisabledBg = Color.accentColor.opacity(0.4)

    // Macro colors
    static let macroProtein = DesignTokens.Colors.protein
    static let macroCarbs   = DesignTokens.Colors.carbs
    static let macroFat     = DesignTokens.Colors.fat

    static let starRating = accent

    // MARK: - Typography (SF Pro — Apple Native)
    static let titleFont: Font         = .system(size: 32, weight: .bold)
    static let titleTracking: CGFloat  = -0.8

    static let subtitleFont: Font      = .system(size: 16)
    static let bodyFont: Font          = .system(size: 17, weight: .medium)
    static let captionFont: Font       = .system(size: 13)
    static let buttonFont: Font        = .system(size: 17, weight: .semibold)

    static let largeNumberFont: Font       = .system(size: 48, weight: .bold, design: .rounded)
    static let largeNumberTracking: CGFloat = -2.0

    static let cardLabelFont: Font = .system(size: 17, weight: .semibold)

    // MARK: - Dimensions (aliases → DesignTokens.Layout)
    static let screenPadding: CGFloat          = DesignTokens.Layout.screenMargin
    static let cardCornerRadius: CGFloat       = DesignTokens.Layout.smallCardCornerRadius
    static let buttonCornerRadius: CGFloat     = DesignTokens.Layout.buttonCornerRadius
    static let buttonHeight: CGFloat           = DesignTokens.Layout.buttonHeight
    static let backButtonSize: CGFloat         = DesignTokens.Layout.minTapTarget
    static let backButtonCornerRadius: CGFloat = 22
    static let cardPadding: CGFloat            = DesignTokens.Layout.screenMargin
    static let optionCardHeight: CGFloat       = 60
    static let optionCardSpacing: CGFloat      = DesignTokens.Layout.itemGap
    static let progressBarHeight: CGFloat      = 3
    static let progressBarSpacing: CGFloat     = DesignTokens.Layout.microGap
    static let phoneMockupWidth: CGFloat       = 260
    static let phoneMockupHeight: CGFloat      = 520
    static let phoneMockupCornerRadius: CGFloat = 36
    static let phoneMockupInnerRadius: CGFloat  = 28

    // MARK: - Shadows (flat design — zeroed)
    static let cardShadow   = OnboardingShadow(color: .clear, radius: 0, y: 0)
    static let phoneShadow  = OnboardingShadow(color: .clear, radius: 0, y: 0)
    static let buttonShadow = OnboardingShadow(color: .clear, radius: 0, y: 0)

    // MARK: - Animation
    static let defaultSpring   = Animation.spring(response: 0.35, dampingFraction: 0.85)
    static let quickSpring     = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let slideTransition = Animation.easeInOut(duration: 0.25)
}

// MARK: - Shadow Model

struct OnboardingShadow {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
