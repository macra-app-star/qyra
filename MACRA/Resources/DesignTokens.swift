import SwiftUI

enum DesignTokens {

    // MARK: - Colors (Apple Semantic Palette)

    enum Colors {
        // MARK: - Custom Neutral Scale (uxdam Gray Palette)
        // Light: White 100 #FFFFFF → White 60 #BFC6D4
        // Dark:  Black 100 #0A0E15 → Black 60 #667085
        static let neutral100 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.039, green: 0.055, blue: 0.082, alpha: 1)   // #0A0E15
            : .white                                                       // #FFFFFF
        })
        static let neutral90 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.125, green: 0.145, blue: 0.192, alpha: 1)   // #202531
            : UIColor(red: 0.941, green: 0.945, blue: 0.961, alpha: 1)   // #F0F1F5
        })
        static let neutral80 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.216, green: 0.251, blue: 0.310, alpha: 1)   // #37404F
            : UIColor(red: 0.878, green: 0.894, blue: 0.922, alpha: 1)   // #E0E4EB
        })
        static let neutral70 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.306, green: 0.341, blue: 0.400, alpha: 1)   // #4E5766
            : UIColor(red: 0.820, green: 0.839, blue: 0.878, alpha: 1)   // #D1D6E0
        })
        static let neutral60 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.400, green: 0.439, blue: 0.522, alpha: 1)   // #667085
            : UIColor(red: 0.749, green: 0.776, blue: 0.831, alpha: 1)   // #BFC6D4
        })

        // MARK: - Backgrounds
        static let primaryBackground = Color(.systemGroupedBackground)
        static let secondaryBackground = Color(.secondarySystemGroupedBackground)
        static let cardBackground = Color(.secondarySystemGroupedBackground)

        // MARK: - Text
        static let textPrimary = Color(.label)
        static let textSecondary = Color(.secondaryLabel)
        static let textTertiary = Color(.tertiaryLabel)
        static let textQuaternary = Color(.quaternaryLabel)

        // MARK: - Tint (single source of truth for ALL interactive blue)
        static let tint = Color.accentColor

        // MARK: - Macro Colors (all accentColor — label provides identity)
        static let protein = Color.accentColor
        static let carbs = Color.accentColor
        static let fat = Color.accentColor
        static let calories = Color.accentColor

        // MARK: - Ring Colors
        static let ringProtein = Color.accentColor
        static let ringCarbs = Color.accentColor
        static let ringFat = Color.accentColor
        static let ringCalories = Color.accentColor
        static let calorieRing = Color.accentColor
        static let calorieRingTrack = Color(.systemGray5)
        static let ringTrack = Color(.systemGray5)
        static let ringTrackLight = Color(.systemGray6)

        // MARK: - Activity
        static let move = Color.red
        static let exercise = Color.green
        static let stand = Color.cyan

        // MARK: - Feature Colors
        static let water = Color.cyan
        static let fasting = Color.orange
        static let fiber = Color.green
        static let sugar = Color.orange
        static let sodium = Color.purple
        static let ringFiber = Color.green
        static let ringSugar = Color.orange
        static let ringSodium = Color.purple

        // MARK: - Semantic
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let destructive = Color.red

        // MARK: - UI Elements
        static let separator = Color(.separator)
        static let fill = Color(.systemFill)
        static let secondaryFill = Color(.secondarySystemFill)
        static let border = Color(.separator)

        // MARK: - AI Intelligence
        static let aiAccent = Color.accentColor
        static let aiTint = Color.accentColor

        // MARK: - Streaks & Achievements
        static let streak = Color.orange
        static let badge = Color.yellow

        // MARK: - Charts
        static let burnedColor = Color.red
        static let consumedColor = Color.accentColor
        static let netEnergy = Color(.label)

        // MARK: - BMI Scale
        static let bmiBlue = Color.accentColor
        static let bmiGreen = Color.green
        static let bmiYellow = Color.yellow
        static let bmiRed = Color.red

        // MARK: - Groups
        static let groupCreate = Color.green
        static let groupJoin = Color.accentColor

        // MARK: - Legacy Aliases (map old names to new values — preserve ALL existing property names)

        // Brand
        static let ink = Color(.label)
        static let chalk = Color(.systemBackground)
        static let accent = tint
        static let brandTeal = tint
        static let brandAccent = tint

        // Backgrounds
        static let background = primaryBackground
        static let surface = Color(.systemGroupedBackground)
        static let surfaceElevated = Color(.secondarySystemGroupedBackground)

        // Buttons
        static let buttonPrimary = tint
        static let buttonPrimaryText = Color.white

        // Text aliases
        static let textPrimaryOnLight = textPrimary

        // Divider
        static let divider = separator

        // Legacy named colors
        static let electricBlue = tint
        static let performanceGreen = success
        static let energyOrange = streak

        // Health score
        static let healthScoreAccent = Color.accentColor
        static let healthScoreBackground = Color(.secondarySystemGroupedBackground)

        // AI Coach
        static let aiCoachBackground = Color(.secondarySystemGroupedBackground)

        // Overlay
        static let overlayDim = Color.black.opacity(0.4)

        // Tab/Pill colors
        static let tabActive = tint
        static let tabInactive = Color(.secondaryLabel)
        static let pillActive = tint
        static let pillActiveText = Color.white
        static let pillInactive = Color(.secondarySystemFill)
        static let pillInactiveText = Color(.label)

        // Legacy pill aliases
        static let selectedPillBg = tint
        static let selectedPillText = Color.white
        static let unselectedPillText = Color(.secondaryLabel)

        // Leaderboard
        static let leaderboardGold = Color.yellow
        static let leaderboardSilver = Color.gray
        static let leaderboardBronze = Color.orange

        // Avatar colors
        static let avatarColors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan]

        // Phase 3 legacy aliases
        static let streakOrange = Color.orange
        static let waterBlue = Color.cyan

        static let healthGreen = Color.green
        static let chartOrange = Color.orange

        // Charts legacy
        static let burnedCoral = Color.red

        // Exercise
        static let exerciseRing = Color.red
        static let exerciseRingTrack = Color(.systemGray5)

        // Badges
        static let badgeLocked = Color(.systemGray4)
        static let badgeUnlocked = Color.green
    }

    // MARK: - Typography (SF Pro — Apple Native)

    enum Typography {
        // Display — splash, paywall headline
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .black)
        }
        // Headline — section headers, bold text
        static func headlineFont(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold)
        }
        // Semibold — card titles, nav items
        static func semibold(_ size: CGFloat) -> Font {
            .system(size: size, weight: .semibold)
        }
        // Medium — labels, field titles
        static func medium(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium)
        }
        // Body — descriptions
        static func bodyFont(_ size: CGFloat) -> Font {
            .system(size: size)
        }
        // Light — decorative, large text
        static func light(_ size: CGFloat) -> Font {
            .system(size: size, weight: .light)
        }
        // Label — metadata, timestamps
        static func label(_ size: CGFloat) -> Font {
            .system(size: size, weight: .medium)
        }
        // Numeric — ring numbers, calorie display (SF Pro Rounded)
        static func numeric(_ size: CGFloat) -> Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
        // Icon — SF Symbol sizing
        static func icon(_ size: CGFloat) -> Font {
            .system(size: size)
        }

        // Standard sizes (backward compatible)
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.body
        static let callout = Font.system(size: 16)
        static let subheadline = Font.system(size: 15)
        static let footnote = Font.system(size: 13)
        static let caption = Font.system(size: 12)
        static let caption2 = Font.system(size: 11)
        static let monoLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        static let monoMedium = Font.system(size: 32, weight: .bold, design: .rounded)
        static let monoSmall = Font.system(size: 20, weight: .bold, design: .rounded)
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

    // MARK: - Layout Constants

    enum Layout {
        // Status bar & navigation
        static let statusBarHeight: CGFloat = 44
        static let homeIndicatorHeight: CGFloat = 34
        static let navBarHeight: CGFloat = 56
        static let backButtonSize: CGFloat = 44
        static let navToContentGap: CGFloat = 8

        // Content positioning
        static let contentTopInset: CGFloat = 96
        static let titleToSubtitle: CGFloat = 8
        static let textContainerHeight: CGFloat = 80

        // Horizontal margins
        static let screenMargin: CGFloat = 20
        static let cardInternalPadding: CGFloat = 16
        static let sectionHorizontalPadding: CGFloat = 24

        // Input fields
        static let inputFieldHeight: CGFloat = 56
        static let inputFieldMargin: CGFloat = 16
        static let textToInputGap: CGFloat = 24

        // Buttons
        static let buttonHeight: CGFloat = 56
        static let buttonCornerRadius: CGFloat = 28
        static let buttonWidth: CGFloat = 343
        static let buttonToKeyboardGap: CGFloat = 16
        static let contentToButtonGap: CGFloat = 24

        // Vertical rhythm
        static let sectionGap: CGFloat = 32
        static let cardGap: CGFloat = 16
        static let itemGap: CGFloat = 12
        static let tightGap: CGFloat = 8
        static let microGap: CGFloat = 4

        // Card radii
        static let cardCornerRadius: CGFloat = 12
        static let smallCardCornerRadius: CGFloat = 12
        static let ringCardCornerRadius: CGFloat = 12

        // Tab bar & FAB
        static let tabBarHeight: CGFloat = 49
        static let fabBottomPadding: CGFloat = 80
        static let minTapTarget: CGFloat = 44
    }

    // MARK: - Corner Radius

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 20
        static let full: CGFloat = 9999
    }

    // MARK: - FAB

    enum FAB {
        static let size: CGFloat = 56
        static let cornerRadius: CGFloat = 28
        static let iconSize: CGFloat = 24
        static let trailingInset: CGFloat = 20
        static let menuItemSize: CGFloat = 120
    }

    // MARK: - Gradients

    // MARK: - Gradients (rings now use solid colors; kept for backward compatibility)

    enum Gradients {
        // Solid-color gradients — rings are now flat Apple Activity Ring style
        static let calorieRing = AngularGradient(
            colors: [Colors.calorieRing, Colors.calorieRing],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
        static let proteinRing = LinearGradient(
            colors: [Colors.ringProtein, Colors.ringProtein],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let carbsRing = LinearGradient(
            colors: [Colors.ringCarbs, Colors.ringCarbs],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let fatRing = LinearGradient(
            colors: [Colors.ringFat, Colors.ringFat],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: - Shadows (kept for backward compatibility but values zeroed for flat design)

    enum Shadows {
        static let subtle = Color.clear
        static let medium = Color.clear
        static let elevated = Color.clear
    }

    // MARK: - Animation

    enum Anim {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.default
        static let spring = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.85)
        static let ring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
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
