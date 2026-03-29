import SwiftUI

struct WeightChangesSection: View {
    let changes: [ProgressViewModel.WeightChange]

    private var hasData: Bool {
        changes.contains { $0.change != nil }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Weight Changes")
                .font(DesignTokens.Typography.headlineFont(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if hasData {
                dataRows
            } else {
                emptyState
            }
        }
    }

    private var dataRows: some View {
        VStack(spacing: 0) {
            ForEach(Array(changes.enumerated()), id: \.element.id) { index, change in
                changeRow(change: change)

                if index < changes.count - 1 {
                    Divider()
                        .background(DesignTokens.Colors.separator)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func changeRow(change: ProgressViewModel.WeightChange) -> some View {
        HStack {
            Text(change.period)
                .font(DesignTokens.Typography.medium(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            if let value = change.change {
                Text(String(format: "%+.1f lbs", value))
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(
                        change.isPositive == true
                            ? DesignTokens.Colors.healthGreen
                            : DesignTokens.Colors.destructive
                    )

                Image(systemName: change.isPositive == true ? "arrow.down.right" : "arrow.up.right")
                    .font(DesignTokens.Typography.icon(12))
                    .foregroundStyle(
                        change.isPositive == true
                            ? DesignTokens.Colors.healthGreen
                            : DesignTokens.Colors.destructive
                    )
            } else {
                Text("\u{2014} lbs")
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)

                Image(systemName: "minus")
                    .font(DesignTokens.Typography.icon(12))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }

    private var emptyState: some View {
        EmptyDataView(
            title: "No Weight Data",
            subtitle: "Log weight regularly to see week-over-week changes."
        )
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

#Preview {
    VStack(spacing: DesignTokens.Spacing.lg) {
        // Empty state
        WeightChangesSection(changes: [])

        // With nil data
        WeightChangesSection(changes: [
            .init(period: "3d", change: nil, isPositive: nil),
            .init(period: "7d", change: nil, isPositive: nil),
            .init(period: "14d", change: nil, isPositive: nil),
            .init(period: "30d", change: nil, isPositive: nil),
            .init(period: "90d", change: nil, isPositive: nil),
            .init(period: "All", change: nil, isPositive: nil),
        ])
    }
    .padding()
    .background(DesignTokens.Colors.background)
}
