import SwiftUI

struct BarChartView: View {
    let data: [(label: String, value: Double)]
    var barColor: Color = DesignTokens.Colors.chartOrange
    var maxValue: Double = 0

    private let barCornerRadius: CGFloat = 4
    private let yAxisLabelCount = 4

    @State private var animateIn = false

    private var resolvedMax: Double {
        let dataMax = data.map(\.value).max() ?? 1
        let effective = maxValue > 0 ? maxValue : dataMax
        return effective > 0 ? effective : 1
    }

    private var yAxisLabels: [Double] {
        let step = resolvedMax / Double(yAxisLabelCount)
        return (0...yAxisLabelCount).map { Double($0) * step }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // Y-axis labels
            yAxis

            // Chart area
            chartArea
        }
        .onAppear {
            withAnimation(DesignTokens.Anim.spring.delay(0.1)) {
                animateIn = true
            }
        }
    }

    private var yAxis: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(yAxisLabels.reversed(), id: \.self) { value in
                Text("\(Int(value))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(width: 32)
        .padding(.bottom, 20) // offset for x-axis labels
    }

    private var chartArea: some View {
        GeometryReader { geo in
            let chartHeight = geo.size.height - 20 // reserve for x-axis labels
            let barWidth = geo.size.width / CGFloat(data.count)

            ZStack(alignment: .bottomLeading) {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<(yAxisLabelCount + 1), id: \.self) { _ in
                        Divider()
                            .overlay(Color(.separator))
                            .frame(height: 0.5)
                            .dash()
                            .frame(maxHeight: .infinity, alignment: .top)
                    }
                }
                .frame(height: chartHeight)

                // Bars and labels
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: DesignTokens.Spacing.xs) {
                            // Bar
                            let fraction = animateIn ? min(item.value / resolvedMax, 1.0) : 0
                            let barHeight = max(fraction * chartHeight, 0)

                            Spacer(minLength: 0)

                            UnevenRoundedRectangle(
                                topLeadingRadius: barCornerRadius,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: barCornerRadius
                            )
                            .fill(barColor)
                            .frame(
                                width: max(barWidth * 0.5, 4),
                                height: barHeight
                            )

                            // X-axis label
                            Text(item.label)
                                .font(.caption)
                                .foregroundStyle(Color(.secondaryLabel))
                                .frame(height: 16)
                        }
                        .frame(width: barWidth)
                    }
                }
            }
        }
    }
}

// MARK: - Dashed line modifier

private extension View {
    func dash() -> some View {
        mask(
            HStack(spacing: 4) {
                ForEach(0..<60, id: \.self) { _ in
                    Rectangle()
                        .frame(width: 4, height: 0.5)
                }
            }
        )
    }
}

#Preview {
    let sampleData: [(label: String, value: Double)] = [
        ("Mon", 1850),
        ("Tue", 2100),
        ("Wed", 1600),
        ("Thu", 2400),
        ("Fri", 1900),
        ("Sat", 2200),
        ("Sun", 1750)
    ]

    BarChartView(
        data: sampleData,
        barColor: DesignTokens.Colors.chartOrange,
        maxValue: 2500
    )
    .frame(height: 180)
    .padding(DesignTokens.Spacing.md)
    .background(DesignTokens.Colors.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    .padding(DesignTokens.Spacing.md)
    .background(DesignTokens.Colors.background)
}
