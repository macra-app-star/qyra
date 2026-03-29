import SwiftUI

struct RingColorsExplainedView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Calendar icon
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.buttonPrimary)
                        .frame(width: 56, height: 56)
                    Image(systemName: "calendar")
                        .font(DesignTokens.Typography.medium(24))
                        .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                }
                .padding(.top, DesignTokens.Spacing.sm)

                // Description
                Text("Your calendar view uses colored rings to give you a quick overview of how each day went nutritionally.")
                    .font(DesignTokens.Typography.bodyFont(16))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineSpacing(4)

                // Legend header
                Text("LEGEND")
                    .font(DesignTokens.Typography.medium(13))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(.top, DesignTokens.Spacing.sm)

                // Legend entries
                VStack(spacing: 0) {
                    legendRow(
                        ringColor: .green,
                        isDashed: false,
                        title: "Green Ring",
                        description: "Within 100 calories of your daily goal or less remaining. Great job!"
                    )

                    Divider()
                        .padding(.leading, 56)

                    legendRow(
                        ringColor: Color(red: 0.80, green: 0.60, blue: 0.00),
                        isDashed: false,
                        title: "Yellow Ring",
                        description: "Within 200 calories surplus of your daily goal. Slightly over target."
                    )

                    Divider()
                        .padding(.leading, 56)

                    legendRow(
                        ringColor: .red,
                        isDashed: false,
                        title: "Red Ring",
                        description: "More than 200 calories remaining or significantly over your goal."
                    )

                    Divider()
                        .padding(.leading, 56)

                    legendRow(
                        ringColor: Color(.systemGray4),
                        isDashed: true,
                        title: "Dotted Gray Ring",
                        description: "No meals have been logged for this day yet."
                    )
                }

                // Tip
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "lightbulb.fill")
                        .font(DesignTokens.Typography.icon(22))
                        .foregroundStyle(DesignTokens.Colors.healthScoreAccent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tip")
                            .font(DesignTokens.Typography.semibold(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("Tap any day on the calendar to see a detailed breakdown of your meals and macros.")
                            .font(DesignTokens.Typography.bodyFont(14))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                .padding(.top, DesignTokens.Spacing.lg)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Ring Colors Explained")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legendRow(ringColor: Color, isDashed: Bool, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            // Ring preview
            ZStack {
                if isDashed {
                    Circle()
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 3, dash: [4, 3]))
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .stroke(ringColor, lineWidth: 3)
                        .frame(width: 32, height: 32)
                }
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.Typography.semibold(17))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text(description)
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
}
