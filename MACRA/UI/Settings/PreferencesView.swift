import SwiftUI

struct PreferencesView: View {
    @Environment(ThemeManager.self) private var themeManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("badgeCelebrations") private var badgeCelebrations = true
    @AppStorage("liveActivity") private var liveActivity = true
    @AppStorage("addBurnedCalories") private var addBurnedCalories = true
    @AppStorage("rolloverCalories") private var rolloverCalories = false
    @AppStorage("autoAdjustMacros") private var autoAdjustMacros = false
    @AppStorage("workoutReminderEnabled") private var workoutReminderEnabled = false
    @AppStorage("workoutReminderHour") private var workoutReminderHour = 6
    @AppStorage("workoutReminderMinute") private var workoutReminderMinute = 0

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Appearance Card
                appearanceCard

                // Preferences List Card
                preferencesCard
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(DesignTokens.Colors.neutral90)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Go back")
                .accessibilityAddTraits(.isButton)
            }
        }
    }

    // MARK: - Appearance Card

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Appearance")
                    .font(DesignTokens.Typography.semibold(18))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Choose light, dark, or system appearance")
                    .font(DesignTokens.Typography.bodyFont(14))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                appearanceMockup(mode: .system, icon: "circle.lefthalf.filled", label: "System")
                appearanceMockup(mode: .light, icon: "sun.max.fill", label: "Light")
                appearanceMockup(mode: .dark, icon: "moon.fill", label: "Dark")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func appearanceMockup(mode: ThemeManager.Mode, icon: String, label: String) -> some View {
        let isSelected = themeManager.mode == mode
        let isDarkPreview = mode == .dark

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                themeManager.mode = mode
            }
            DesignTokens.Haptics.light()
        } label: {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Phone mockup
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isDarkPreview ? Color(hex: "0A0E15") : Color(hex: "F0F1F5"))
                        .frame(height: 90)

                    VStack(spacing: 5) {
                        // Status bar
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(isDarkPreview ? Color.white.opacity(0.3) : Color.black.opacity(0.12))
                                .frame(width: 28, height: 4)
                            Spacer()
                            Circle()
                                .fill(isDarkPreview ? Color.white.opacity(0.25) : Color.black.opacity(0.1))
                                .frame(width: 6, height: 6)
                        }
                        .padding(.horizontal, 8)

                        // Content blocks
                        HStack(spacing: 4) {
                            ForEach(0..<3, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isDarkPreview ? Color.white.opacity(0.12) : Color.black.opacity(0.06))
                                    .frame(height: 28)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                i == 0 ? Color.red.opacity(isDarkPreview ? 0.6 : 0.4)
                                                : i == 1 ? Color.orange.opacity(isDarkPreview ? 0.6 : 0.4)
                                                : Color.accentColor.opacity(isDarkPreview ? 0.6 : 0.4),
                                                lineWidth: 1.5
                                            )
                                            .frame(width: 14, height: 14)
                                    )
                            }
                        }
                        .padding(.horizontal, 8)

                        // Bottom indicators
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { _ in
                                Circle()
                                    .fill(isDarkPreview ? Color.white.opacity(0.15) : Color.black.opacity(0.08))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? DesignTokens.Colors.textPrimary : Color.clear, lineWidth: 2)
                )

                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                    Text(label)
                        .font(DesignTokens.Typography.medium(13))
                }
                .foregroundStyle(DesignTokens.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preferences Card

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            preferenceToggle(
                title: "Badge celebrations",
                description: "Show a full-screen badge animation when you unlock a new badge",
                isOn: $badgeCelebrations,
                showDivider: true
            )

            preferenceToggle(
                title: "Live activity",
                description: "Show your daily calories and macros on your lock screen and dynamic island",
                isOn: $liveActivity,
                showDivider: true
            )

            preferenceToggle(
                title: "Add burned calories",
                description: "Add burned calories back to daily goal",
                isOn: $addBurnedCalories,
                showDivider: true
            )

            preferenceToggle(
                title: "Rollover calories",
                description: "Add up to 200 left over calories from yesterday into today's daily goal",
                isOn: $rolloverCalories,
                showDivider: true
            )

            preferenceToggle(
                title: "Auto adjust macros",
                description: "When editing calories or macronutrients, automatically adjust the other values proportionally",
                isOn: $autoAdjustMacros,
                showDivider: false
            )
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

    private func preferenceToggle(title: String, description: String, isOn: Binding<Bool>, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(title)
                        .font(DesignTokens.Typography.semibold(16))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    Text(description)
                        .font(DesignTokens.Typography.bodyFont(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Toggle("", isOn: isOn)
                    .labelsHidden()
                    .tint(.accentColor)
            }
            .padding(.vertical, DesignTokens.Spacing.md)

            if showDivider {
                Divider()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PreferencesView()
            .environment(ThemeManager())
    }
}
