import SwiftUI

// QYRA DESIGN SYSTEM — COLOR EXCEPTIONS REGISTRY
// All color exceptions from the single-accent rule must be listed here.
// Do not add new exceptions without design review.

enum QyraDesignSystem {

    // MARK: - Accent Color (Universal)
    // All interactive elements use Color.accentColor (#007AFF / Apple System Blue)
    // This is the only permitted UI accent color.

    // MARK: - Permitted Color Exceptions

    /// Streak indicators only. Orange flame + streak counter.
    /// Applies to: streak flame icon, day streak counter, milestone streak badges.
    /// Do NOT use for: progress bars, CTA buttons, charts, rings, or any non-streak element.
    static let streakColor = Color.orange

    /// BMI scale gradient. A continuous health-range visualization.
    /// Applies to: BMIScaleView gradient bar only.
    /// Rationale: Medical visualization standard for BMI risk zones.
    /// Do NOT use for decorative gradients or as a general progress indicator.
    static let bmiScaleGradient = LinearGradient(
        colors: [.blue, .green, Color(.systemYellow), .orange, .red],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Calendar day ring colors. Traffic-light nutritional adherence system.
    /// Green = within 100 cal of daily goal or less remaining.
    /// Yellow = within 200 cal surplus of daily goal.
    /// Red = more than 200 cal remaining OR significantly over goal.
    /// Gray (dashed) = no meals logged.
    /// Applies to: CalendarDayRingView only.
    /// Rationale: Semantic traffic-light system — color IS the information, not decoration.
    /// Do NOT use in any other ring, chart, or progress indicator.
    static let calendarRingColors = CalendarRingColorSystem()

    struct CalendarRingColorSystem {
        let onTarget = Color.green
        let slightlyOver = Color.yellow
        let offTarget = Color(.systemRed)
        let noData = Color(.systemGray4)
    }

    // MARK: - Forbidden Colors (Do Not Use)
    // The following colors are NEVER permitted outside of the exceptions above:
    // - Color.red (only in system destructive actions via role:.destructive)
    // - Color.orange (only via streakColor above)
    // - Any gradient (only via bmiScaleGradient above)
    // - Hardcoded hex colors anywhere in the codebase
    // - Color.purple (never permitted, including AI surfaces)
    // - Color.green (only via calendarRingColors above)
}
