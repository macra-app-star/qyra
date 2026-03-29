import SwiftUI

struct WaterDetailView: View {
    @State private var waterOunces: Int = 0
    @State private var waterGoal: Int = 64
    @State private var waterEntries: [(id: UUID, amount: Int, time: Date)] = []
    @Environment(\.dismiss) private var dismiss

    private var progress: Double {
        waterGoal > 0 ? min(Double(waterOunces) / Double(waterGoal), 1.0) : 0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Water ring
                waterRing

                // Quick add buttons
                quickAddSection

                // Today's log
                todayLogSection
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Water")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Water Ring

    private var waterRing: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.ringTrack, style: StrokeStyle(lineWidth: 14, lineCap: .round))

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(DesignTokens.Colors.water, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(DesignTokens.Anim.ring, value: progress)

                VStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "drop.fill")
                        .font(DesignTokens.Typography.icon(28))
                        .foregroundStyle(DesignTokens.Colors.water)

                    Text("\(waterOunces)")
                        .font(DesignTokens.Typography.numeric(36))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text("of \(waterGoal) oz")
                        .font(DesignTokens.Typography.bodyFont(14))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            .frame(width: 200, height: 200)
            .padding(.top, DesignTokens.Spacing.lg)
        }
    }

    // MARK: - Quick Add

    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Quick Add")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            HStack(spacing: DesignTokens.Spacing.sm) {
                quickAddButton(icon: "cup.and.saucer.fill", label: "Cup", amount: "8 oz", value: 8)
                quickAddButton(icon: "waterbottle.fill", label: "Bottle", amount: "16 oz", value: 16)
                quickAddButton(icon: "drop.fill", label: "Large", amount: "24 oz", value: 24)
                quickAddButton(icon: "slider.horizontal.3", label: "Custom", amount: "", value: 0)
            }
        }
    }

    private func quickAddButton(icon: String, label: String, amount: String, value: Int) -> some View {
        Button {
            if value > 0 {
                withAnimation(DesignTokens.Anim.standard) {
                    waterOunces += value
                    waterEntries.insert((id: UUID(), amount: value, time: Date()), at: 0)
                }
            }
        } label: {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(DesignTokens.Typography.icon(22))
                    .foregroundStyle(DesignTokens.Colors.water)

                Text(label)
                    .font(DesignTokens.Typography.medium(14))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                if !amount.isEmpty {
                    Text(amount)
                        .font(DesignTokens.Typography.bodyFont(12))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    // MARK: - Today's Log

    private var todayLogSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Today's Log")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if waterEntries.isEmpty {
                EmptyDataView(
                    title: "No Water Logged",
                    subtitle: "Use the quick add buttons above to start tracking."
                )
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            } else {
                ForEach(waterEntries, id: \.id) { entry in
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(DesignTokens.Typography.icon(16))
                            .foregroundStyle(DesignTokens.Colors.water)

                        Text("\(entry.amount) oz")
                            .font(DesignTokens.Typography.medium(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Text(entry.time, style: .time)
                            .font(DesignTokens.Typography.bodyFont(14))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
            }
        }
    }
}
