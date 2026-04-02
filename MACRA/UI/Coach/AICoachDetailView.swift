import SwiftUI

struct AICoachDetailView: View {
    let vm: DashboardViewModel
    @State private var mealRemindersOn = true
    @State private var eveningCheckInOn = true
    @State private var streakProtectionOn = true

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Hero card
                heroCard

                // Today's Tips
                tipsSection

                // Today's Snapshot
                snapshotSection

                // Smart Alerts
                smartAlertsSection

                // Disclaimer
                Text("Qyra AI provides general wellness guidance and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult a qualified healthcare provider with questions about your health.")
                    .font(DesignTokens.Typography.bodyFont(12))
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, DesignTokens.Spacing.sm)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("AI Coach")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("\u{2728}\u{2728}")
                .font(DesignTokens.Typography.icon(32))
                .padding(.top, DesignTokens.Spacing.md)

            Text(vm.coachHeadline)
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            statusBadge

            Text(vm.coachMessage)
                .font(DesignTokens.Typography.bodyFont(14))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.bottom, DesignTokens.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
    }

    private var statusBadge: some View {
        let calPct = vm.calorieGoal > 0 ? vm.currentCalories / vm.calorieGoal : 0

        let label: String
        let color: Color

        if vm.meals.isEmpty {
            label = "Not Started"
            color = DesignTokens.Colors.textSecondary
        } else if calPct > 1.2 {
            label = "Over Budget"
            color = DesignTokens.Colors.protein
        } else {
            label = "On Track"
            color = DesignTokens.Colors.brandAccent
        }

        return Text(label)
            .font(DesignTokens.Typography.medium(13))
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Today's Tips")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if vm.coachTips.isEmpty {
                tipRow(icon: "lightbulb.fill", color: DesignTokens.Colors.fasting, text: "Log your first meal to get personalized tips")
                tipRow(icon: "target", color: DesignTokens.Colors.protein, text: "Set your macro goals in Settings")
                tipRow(icon: "sparkles", color: DesignTokens.Colors.fat, text: "Consistency beats perfection every time")
            } else {
                ForEach(Array(vm.coachTips.enumerated()), id: \.offset) { _, tip in
                    tipRow(icon: tip.icon, color: tip.color, text: tip.text)
                }
            }
        }
    }

    private func tipRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(DesignTokens.Typography.medium(15))
                    .foregroundStyle(color)
            }

            Text(text)
                .font(DesignTokens.Typography.bodyFont(15))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Snapshot Section

    private var snapshotSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Today's Snapshot")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.Spacing.sm) {
                snapshotTile(
                    value: "\(Int(vm.currentCalories))",
                    label: "Calories",
                    sublabel: "of \(Int(vm.calorieGoal))",
                    color: DesignTokens.Colors.textPrimary
                )
                snapshotTile(
                    value: "\(Int(vm.currentProtein))g",
                    label: "Protein",
                    sublabel: "of \(Int(vm.proteinGoal))g",
                    color: DesignTokens.Colors.protein
                )
                snapshotTile(
                    value: "\(Int(vm.currentCarbs))g",
                    label: "Carbs",
                    sublabel: "of \(Int(vm.carbGoal))g",
                    color: DesignTokens.Colors.carbs
                )
                snapshotTile(
                    value: "\(Int(vm.currentFat))g",
                    label: "Fat",
                    sublabel: "of \(Int(vm.fatGoal))g",
                    color: DesignTokens.Colors.fat
                )
            }
        }
    }

    private func snapshotTile(value: String, label: String, sublabel: String, color: Color) -> some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(value)
                .font(DesignTokens.Typography.numeric(24))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(label)
                .font(DesignTokens.Typography.medium(14))
                .foregroundStyle(color)

            Text(sublabel)
                .font(DesignTokens.Typography.bodyFont(12))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    // MARK: - Smart Alerts

    private var smartAlertsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text("Smart Alerts")
                .font(DesignTokens.Typography.semibold(17))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            alertRow(
                icon: "fork.knife",
                iconColor: DesignTokens.Colors.aiAccent,
                title: "Meal Reminders",
                subtitle: "Breakfast, lunch, and dinner reminders",
                isOn: $mealRemindersOn
            )

            alertRow(
                icon: "moon.stars.fill",
                iconColor: DesignTokens.Colors.aiAccent,
                title: "Evening Check-in",
                subtitle: "Daily macro review at 8:30 PM",
                isOn: $eveningCheckInOn
            )

            alertRow(
                icon: "flame.fill",
                iconColor: DesignTokens.Colors.aiAccent,
                title: "Streak Protection",
                subtitle: "Alert if no meals logged by 7 PM",
                isOn: $streakProtectionOn
            )
        }
    }

    private func alertRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(DesignTokens.Typography.medium(16))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.semibold(16))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(subtitle)
                    .font(DesignTokens.Typography.bodyFont(13))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DesignTokens.Colors.brandAccent)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}
