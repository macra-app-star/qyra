import SwiftUI
import UIKit

enum QyraFont {
    // MARK: - Semantic Font Methods (SF Pro system styles)
    // Note: methods named to avoid conflict with legacy static let properties below

    static func sectionHeader() -> Font { .title2.weight(.bold) }
    static func cardTitle() -> Font { .headline }
    static func headlineFont() -> Font { .headline }
    static func bodyFont() -> Font { .body }
    static func calloutFont() -> Font { .callout }
    static func subheadlineFont() -> Font { .subheadline }
    static func footnoteFont() -> Font { .footnote }
    static func captionFont() -> Font { .caption }
    static func caption2Font() -> Font { .caption2 }

    // MARK: - Numerical Displays (SF Pro Rounded)

    static func dataNumber() -> Font {
        .system(size: 28, weight: .bold, design: .rounded)
    }

    static func monoNumber(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .medium).monospacedDigit()
    }

    static func dataLabelFont() -> Font {
        .system(size: 13, weight: .regular).monospacedDigit()
    }

    // MARK: - Brand Wordmark

    static func wordmark() -> Font {
        .system(size: 24, weight: .heavy)
    }

    // MARK: - Legacy Parametric Constructors (keep so 57+ files compile without changes)
    // These map old Playfair Display calls to SF Pro system font equivalents

    static func regular(_ size: CGFloat) -> Font { .system(size: size) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
    static func extraBold(_ size: CGFloat) -> Font { .system(size: size, weight: .heavy) }
    static func black(_ size: CGFloat) -> Font { .system(size: size, weight: .black) }

    static func italic(_ size: CGFloat) -> Font { .system(size: size).italic() }
    static func boldItalic(_ size: CGFloat) -> Font { .system(size: size, weight: .bold).italic() }

    // MARK: - Legacy Static Constants (referenced as QyraFont.headline, etc.)

    static let largeTitle    = Font.largeTitle.weight(.bold)
    static let title1        = Font.system(size: 32, weight: .bold)
    static let title2        = Font.system(size: 28, weight: .bold)
    static let title3        = Font.system(size: 24, weight: .bold)
    static let headline      = Font.system(size: 20, weight: .semibold)
    static let body          = Font.body
    static let bodyBold      = Font.system(size: 17, weight: .bold)
    static let callout       = Font.system(size: 16, weight: .medium)
    static let subheadline   = Font.system(size: 15, weight: .medium)
    static let footnote      = Font.system(size: 14)
    static let footnoteBold  = Font.system(size: 14, weight: .bold)
    static let caption1      = Font.system(size: 13)
    static let caption2      = Font.system(size: 12)
    static let caption2Bold  = Font.system(size: 12, weight: .bold)
    static let micro         = Font.system(size: 11)
    static let microBold     = Font.system(size: 11, weight: .bold)

    // MARK: - Specific Use Cases

    static let splashLogo    = Font.system(size: 42, weight: .black)
    static let bigNumber     = Font.system(size: 48, weight: .bold, design: .rounded)
    static let hugeNumber    = Font.system(size: 64, weight: .bold, design: .rounded)
    static let buttonLabel   = Font.system(size: 17, weight: .semibold)
    static let tabLabel      = Font.caption2
    static let badgeLabel    = Font.system(size: 12, weight: .bold)
    static let ringNumberConst = Font.system(size: 22, weight: .bold, design: .rounded)
    static let streakNumber  = Font.system(size: 40, weight: .bold, design: .rounded)

    // MARK: - UIKit Bridge (for UINavigationBar / UITabBar appearance proxies)

    static func uiFont(_ weight: UIFont.Weight, size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: weight)
    }
}
