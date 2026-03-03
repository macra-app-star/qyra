import SwiftUI

enum DesignTokens {

    // MARK: - Colors (Monochrome)

    enum Colors {
        static let background = Color.black
        static let surface = Color(white: 0.08)
        static let surfaceElevated = Color(white: 0.12)
        static let border = Color(white: 0.18)
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.60)
        static let textTertiary = Color(white: 0.40)
        static let accent = Color.white
        static let destructive = Color.red.opacity(0.85)

        static let ringProtein = Color.white
        static let ringCarbs = Color(white: 0.70)
        static let ringFat = Color(white: 0.50)
        static let ringCalories = Color.white
        static let ringTrack = Color(white: 0.15)
    }

    // MARK: - Typography (SF Pro)

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
        static let title = Font.system(size: 28, weight: .bold, design: .default)
        static let title2 = Font.system(size: 22, weight: .bold, design: .default)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let headline = Font.system(size: 17, weight: .semibold, design: .default)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let callout = Font.system(size: 16, weight: .regular, design: .default)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        static let monoLarge = Font.system(size: 48, weight: .thin, design: .monospaced)
        static let monoMedium = Font.system(size: 32, weight: .light, design: .monospaced)
        static let monoSmall = Font.system(size: 20, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadows {
        static let subtle = Color.white.opacity(0.05)
        static let medium = Color.white.opacity(0.1)
    }

    // MARK: - Animation

    enum Anim {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let ring = SwiftUI.Animation.easeInOut(duration: 0.8)
    }

    // MARK: - Haptics

    enum Haptics {
        static func light() {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }

        static func medium() {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        static func heavy() {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        static func success() {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        static func error() {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        static func selection() {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}
