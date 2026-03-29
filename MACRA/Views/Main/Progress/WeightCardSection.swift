import SwiftUI

struct WeightCardSection: View {
    let current: Double?
    let start: Double?
    let goal: Double?
    let progress: Double
    let formattedCurrent: String
    let formattedStart: String
    let formattedGoal: String
    let estimatedDate: String?

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Weight")
                .font(DesignTokens.Typography.headlineFont(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(spacing: DesignTokens.Spacing.md) {
                // Current weight
                HStack {
                    Text(formattedCurrent)
                        .font(DesignTokens.Typography.numeric(28))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignTokens.Colors.ringTrack)
                            .frame(height: 8)

                        if progress > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DesignTokens.Colors.brandAccent)
                                .frame(width: geo.size.width * progress, height: 8)
                        }
                    }
                }
                .frame(height: 8)

                // Start / Goal labels
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        Text("Start")
                            .font(DesignTokens.Typography.bodyFont(12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                        if start != nil {
                            Text("\(formattedStart) lbs")
                                .font(DesignTokens.Typography.medium(13))
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xxs) {
                        Text("Goal")
                            .font(DesignTokens.Typography.bodyFont(12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                        if goal != nil {
                            Text("\(formattedGoal) lbs")
                                .font(DesignTokens.Typography.medium(13))
                                .foregroundStyle(DesignTokens.Colors.textSecondary)
                        }
                    }
                }

                // Estimated completion date
                if let estimatedDate {
                    HStack {
                        Image(systemName: "calendar")
                            .font(DesignTokens.Typography.icon(12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                        Text("Estimated: \(estimatedDate)")
                            .font(DesignTokens.Typography.bodyFont(12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        WeightCardSection(
            current: nil,
            start: nil,
            goal: nil,
            progress: 0,
            formattedCurrent: "\u{2014} lbs",
            formattedStart: "\u{2014}",
            formattedGoal: "\u{2014}",
            estimatedDate: nil
        )

        WeightCardSection(
            current: 178.5,
            start: 195,
            goal: 170,
            progress: 0.66,
            formattedCurrent: "178.5 lbs",
            formattedStart: "195",
            formattedGoal: "170",
            estimatedDate: "Jun 15, 2026"
        )
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
