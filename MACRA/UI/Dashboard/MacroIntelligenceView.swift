import SwiftUI

struct MacroIntelligenceView: View {
    @State private var selectedPeriod = "14 Days"

    private let periods = ["7 Days", "14 Days", "30 Days"]

    // Sample data
    private let score = 30
    private let daysLogged = 2
    private let totalDays = 14
    private let consistency = 14

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Period selector
                periodSelector

                // Score ring card
                scoreCard

                // AI Insight
                aiInsightCard

                // Qyra Adherence
                adherenceSection

                // Calorie Trend
                calorieTrendSection

                // Macro Distribution
                macroDistributionSection

                // Best & Worst Days
                bestWorstSection

                // Recommendations
                recommendationsSection
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, 100)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Qyra AI")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(periods, id: \.self) { period in
                Button {
                    withAnimation(DesignTokens.Anim.quick) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period)
                        .font(DesignTokens.Typography.medium(14))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(selectedPeriod == period ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.border, lineWidth: selectedPeriod == period ? 1.5 : 1)
                        )
                }
            }
            Spacer()
        }
    }

    // MARK: - Score Card

    private var scoreCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Score Ring
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.ringTrack, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(DesignTokens.Colors.protein, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(DesignTokens.Typography.numeric(48))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("/ 100")
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(.top, DesignTokens.Spacing.lg)

            // Status
            Text("Getting Started")
                .font(DesignTokens.Typography.semibold(18))
                .foregroundStyle(DesignTokens.Colors.brandAccent)

            // Stats row
            HStack(spacing: DesignTokens.Spacing.xl) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "calendar")
                        .font(DesignTokens.Typography.icon(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("\(daysLogged)/\(totalDays)")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }

                VStack(spacing: 0) {
                    Text("Days Logged")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("%")
                        .font(DesignTokens.Typography.icon(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text("\(consistency)%")
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }

                Text("Consistency")
                    .font(DesignTokens.Typography.bodyFont(12))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
            }
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    // MARK: - AI Insight

    private var aiInsightCard: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.aiAccent.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: "brain.head.profile")
                    .font(DesignTokens.Typography.medium(18))
                    .foregroundStyle(DesignTokens.Colors.aiAccent)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("AI INSIGHT")
                    .font(DesignTokens.Typography.headlineFont(11))
                    .foregroundStyle(DesignTokens.Colors.aiAccent)

                Text("Log a few more days to unlock deeper insights about your nutrition patterns.")
                    .font(DesignTokens.Typography.bodyFont(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineSpacing(2)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    // MARK: - Adherence

    private var adherenceSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Qyra Adherence")
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: DesignTokens.Spacing.sm), GridItem(.flexible(), spacing: DesignTokens.Spacing.sm)], spacing: DesignTokens.Spacing.sm) {
                adherenceCard(icon: "flame.fill", name: "Calories", rating: "Poor", ratingColor: DesignTokens.Colors.protein, value: "3,135", goal: "2,000", progress: 1.0, barColor: DesignTokens.Colors.protein)
                adherenceCard(icon: "bolt.fill", name: "Protein", rating: "Poor", ratingColor: DesignTokens.Colors.protein, value: "276", goal: "150", progress: 1.0, barColor: DesignTokens.Colors.protein)
                adherenceCard(icon: "leaf.fill", name: "Carbs", rating: "Fair", ratingColor: DesignTokens.Colors.carbs, value: "147", goal: "200", progress: 0.74, barColor: DesignTokens.Colors.carbs)
                adherenceCard(icon: "drop.fill", name: "Fat", rating: "Poor", ratingColor: DesignTokens.Colors.protein, value: "84", goal: "65", progress: 1.0, barColor: DesignTokens.Colors.fat)
            }
        }
    }

    private func adherenceCard(icon: String, name: String, rating: String, ratingColor: Color, value: String, goal: String, progress: Double, barColor: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(DesignTokens.Typography.icon(13))
                    .foregroundStyle(barColor)
                Text(name)
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Spacer()

                Text(rating)
                    .font(DesignTokens.Typography.headlineFont(11))
                    .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ratingColor)
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(DesignTokens.Typography.numeric(24))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text("/ \(goal)")
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.Colors.ringTrack)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Calorie Trend

    private var calorieTrendSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Calorie Trend")
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            // Simple bar chart
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Goal line label
                HStack {
                    Spacer()
                    Text("Goal")
                        .font(DesignTokens.Typography.medium(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }

                HStack(alignment: .bottom, spacing: DesignTokens.Spacing.lg) {
                    // Y axis
                    VStack(alignment: .trailing) {
                        Text("2,000")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color(.secondaryLabel))
                        Spacer()
                        Text("0")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .frame(height: 140)

                    // Bars
                    HStack(alignment: .bottom, spacing: DesignTokens.Spacing.xl) {
                        chartBar(value: 1405, max: 5000, label: "Mar 6", color: DesignTokens.Colors.brandAccent)
                        chartBar(value: 4865, max: 5000, label: "Mar 7", color: DesignTokens.Colors.brandAccent)
                    }
                    .frame(maxWidth: .infinity)
                }

                // Dashed goal line (rendered as overlay in real implementation)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private func chartBar(value: Int, max: Int, label: String, color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 40, height: CGFloat(value) / CGFloat(max) * 140)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))
        }
    }

    // MARK: - Macro Distribution

    private var macroDistributionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Macro Distribution")
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.lg) {
                // Donut chart
                ZStack {
                    // Protein segment (45%)
                    Circle()
                        .trim(from: 0, to: 0.45)
                        .stroke(DesignTokens.Colors.protein, style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Carbs segment (24%)
                    Circle()
                        .trim(from: 0.45, to: 0.69)
                        .stroke(DesignTokens.Colors.carbs, style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    // Fat segment (30%)
                    Circle()
                        .trim(from: 0.69, to: 1.0)
                        .stroke(DesignTokens.Colors.fat, style: StrokeStyle(lineWidth: 24, lineCap: .butt))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("kcal")
                            .font(DesignTokens.Typography.bodyFont(12))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("split")
                            .font(DesignTokens.Typography.bodyFont(12))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                }

                // Legend
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    legendItem(color: DesignTokens.Colors.protein, label: "Protein", value: "45%")
                    legendItem(color: DesignTokens.Colors.carbs, label: "Carbs", value: "24%")
                    legendItem(color: DesignTokens.Colors.fat, label: "Fat", value: "30%")
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private func legendItem(color: Color, label: String, value: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 14)

            Text(label)
                .font(DesignTokens.Typography.medium(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(DesignTokens.Typography.semibold(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
        }
    }

    // MARK: - Best & Worst

    private var bestWorstSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Best & Worst Days")
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                // Best Day
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(DesignTokens.Typography.icon(12))
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                        Text("BEST DAY")
                            .font(DesignTokens.Typography.headlineFont(11))
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                    }

                    Text("Mar 6")
                        .font(DesignTokens.Typography.semibold(17))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    HStack(spacing: 4) {
                        Text("1,405")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("cal")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("124")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("P")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("70")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("C")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("40")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("F")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    Text("70% adherence")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))

                // Worst Day
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "arrow.up.forward")
                            .font(DesignTokens.Typography.icon(12))
                            .foregroundStyle(DesignTokens.Colors.protein)
                        Text("NEEDS WORK")
                            .font(DesignTokens.Typography.headlineFont(11))
                            .foregroundStyle(DesignTokens.Colors.protein)
                    }

                    Text("Mar 7")
                        .font(DesignTokens.Typography.semibold(17))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    HStack(spacing: 4) {
                        Text("4,865")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("cal")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("428")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("P")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("224")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("C")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Text("128")
                            .font(DesignTokens.Typography.semibold(14))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                        Text("F")
                            .font(DesignTokens.Typography.icon(10))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }

                    Text("243% adherence")
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .padding(DesignTokens.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            }
        }
    }

    // MARK: - Recommendations

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Recommendations")
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            recommendationCard(
                icon: "calendar.badge.checkmark",
                iconColor: DesignTokens.Colors.protein,
                title: "Log more consistently",
                priority: "HIGH",
                description: "You're logging 14% of days. Aim for daily tracking to see meaningful trends."
            )

            recommendationCard(
                icon: "minus.circle",
                iconColor: DesignTokens.Colors.protein,
                title: "Reduce calorie intake",
                priority: "HIGH",
                description: "You're averaging 3135 cal — 1135 over your 2000 goal."
            )
        }
    }

    private func recommendationCard(icon: String, iconColor: Color, title: String, priority: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(title)
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(priority)
                        .font(DesignTokens.Typography.headlineFont(10))
                        .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DesignTokens.Colors.protein)
                        .clipShape(Capsule())
                }

                Text(description)
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
                    .lineSpacing(2)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}
