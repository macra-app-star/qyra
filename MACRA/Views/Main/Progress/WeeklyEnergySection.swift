import SwiftUI

struct WeeklyEnergySection: View {
    let data: [(label: String, value: Double)]
    let burned: Double
    let consumed: Double
    let netEnergy: Double
    @Binding var filter: String

    private let filters = ["This wk", "Last wk", "2 wk ago", "3 wk ago"]

    private var hasData: Bool {
        data.contains { $0.value > 0 }
    }

    private var maxValue: Double {
        data.map(\.value).max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Weekly Energy")
                .font(DesignTokens.Typography.headlineFont(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            VStack(spacing: DesignTokens.Spacing.md) {
                // Stats row
                HStack(spacing: 0) {
                    energyStat(
                        label: "Burned",
                        value: formatCalories(burned),
                        color: Color(.label)
                    )
                    energyStat(
                        label: "Consumed",
                        value: formatCalories(consumed),
                        color: Color(.label)
                    )
                    energyStat(
                        label: "Net Energy",
                        value: formatCalories(netEnergy),
                        color: Color(.label)
                    )
                }

                // Bar chart
                if hasData {
                    barChart
                } else {
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("No Data")
                            .font(.headline)
                            .foregroundStyle(Color(.label))

                        Text("Log meals and activity to see your energy balance.")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, DesignTokens.Spacing.lg)
                    .frame(maxWidth: .infinity)
                }

                TimeFilterPills(options: filters, selection: $filter)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: DesignTokens.Spacing.sm) {
            ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                VStack(spacing: DesignTokens.Spacing.xs) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.brandAccent)
                        .frame(
                            height: maxValue > 0
                                ? max(CGFloat(item.value / maxValue) * 100, 4)
                                : 4
                        )

                    Text(item.label)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 120)
    }

    private func energyStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xxs) {
            Text(value)
                .font(DesignTokens.Typography.numeric(18))
                .foregroundStyle(color)
            Text(label)
                .font(DesignTokens.Typography.bodyFont(11))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatCalories(_ value: Double) -> String {
        guard value > 0 else { return "0" }
        return "\(Int(value))"
    }
}

#Preview {
    @Previewable @State var filter = "This wk"
    WeeklyEnergySection(
        data: [
            ("Mon", 0), ("Tue", 0), ("Wed", 0),
            ("Thu", 0), ("Fri", 0), ("Sat", 0), ("Sun", 0)
        ],
        burned: 0,
        consumed: 0,
        netEnergy: 0,
        filter: $filter
    )
    .padding()
    .background(DesignTokens.Colors.background)
}
