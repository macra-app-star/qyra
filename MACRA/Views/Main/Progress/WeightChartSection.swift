import SwiftUI
import Charts

private extension Double {
    var cleanWeightString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

struct WeightChartSection: View {
    let weightEntries: [WeightEntry]
    let currentWeight: Double?
    @Binding var filter: String
    @State private var showWeightLog = false

    private let filters = ["90D", "6M", "1Y", "ALL"]

    private var filteredEntries: [WeightEntry] {
        guard !weightEntries.isEmpty else { return [] }
        let now = Date()
        let cutoff: Date?
        switch filter {
        case "90D":
            cutoff = Calendar.current.date(byAdding: .day, value: -90, to: now)
        case "6M":
            cutoff = Calendar.current.date(byAdding: .month, value: -6, to: now)
        case "1Y":
            cutoff = Calendar.current.date(byAdding: .year, value: -1, to: now)
        default:
            cutoff = nil
        }
        if let cutoff {
            return weightEntries.filter { $0.timestamp >= cutoff }
        }
        return weightEntries
    }

    private var weeklyDelta: Double? {
        guard let current = weightEntries.last else { return nil }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        guard let oldEntry = weightEntries.last(where: { $0.timestamp <= sevenDaysAgo }) else { return nil }
        return current.weightLbs - oldEntry.weightLbs
    }

    private var formattedWeeklyDelta: String {
        guard let delta = weeklyDelta else { return "" }
        let sign = delta >= 0 ? "+" : ""
        return "This week: \(sign)\(delta.cleanWeightString) lbs"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            TimeFilterPills(options: filters, selection: $filter)

            if filteredEntries.count < 2 {
                emptyState
            } else {
                chartContent
            }
        }
        .sheet(isPresented: $showWeightLog) {
            NavigationStack {
                WeightHistoryView()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var chartContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Current weight display
            if let weight = currentWeight {
                Text("\(weight.cleanWeightString) lbs")
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                if weeklyDelta != nil {
                    Text(formattedWeeklyDelta)
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            // Chart
            Chart(filteredEntries, id: \.id) { entry in
                LineMark(
                    x: .value("Date", entry.timestamp, unit: .day),
                    y: .value("Weight", entry.weightLbs)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.accentColor)
                PointMark(
                    x: .value("Date", entry.timestamp, unit: .day),
                    y: .value("Weight", entry.weightLbs)
                )
                .foregroundStyle(Color.accentColor)
            }
            .frame(height: 200)
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    AxisGridLine()
                }
            }

            // Log weight button
            Button {
                showWeightLog = true
            } label: {
                Text("Log weight")
                    .font(QyraFont.semibold(15))
                    .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Layout.minTapTarget)
                    .background(DesignTokens.Colors.buttonPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .padding(.horizontal, DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("Track your trend")
                .font(DesignTokens.Typography.headline)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Log your weight to see progress over time")
                .font(DesignTokens.Typography.footnote)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                showWeightLog = true
            } label: {
                Text("Log weight")
                    .font(QyraFont.semibold(15))
                    .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.Layout.minTapTarget)
                    .background(DesignTokens.Colors.buttonPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

#Preview {
    @Previewable @State var filter = "90D"
    WeightChartSection(
        weightEntries: [],
        currentWeight: nil,
        filter: $filter
    )
    .padding()
    .background(DesignTokens.Colors.background)
}
