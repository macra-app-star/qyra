import SwiftUI

struct WidgetsView: View {
    @State private var selectedTab = "Home Screen"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Segmented control
                Picker("", selection: $selectedTab) {
                    Text("Home Screen").tag("Home Screen")
                    Text("Lock Screen").tag("Lock Screen")
                }
                .pickerStyle(.segmented)

                // Widget preview
                widgetPreview

                // How to add widget
                howToSection

                Spacer(minLength: DesignTokens.Spacing.lg)

                // Done button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(DesignTokens.Typography.semibold(17))
                        .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 52)
                        .background(DesignTokens.Colors.buttonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Widgets")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var widgetPreview: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Preview mockup
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.surface)
                .frame(height: 200)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        // Mini widget mockup
                        RoundedRectangle(cornerRadius: 8)
                            .fill(DesignTokens.Colors.background)
                            .frame(width: 120, height: 60)
                            .overlay(
                                HStack(spacing: 6) {
                                    Circle()
                                        .stroke(DesignTokens.Colors.protein.opacity(0.5), lineWidth: 2)
                                        .frame(width: 20, height: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(DesignTokens.Colors.textTertiary.opacity(0.5))
                                            .frame(width: 40, height: 4)
                                        RoundedRectangle(cornerRadius: 1)
                                            .fill(DesignTokens.Colors.textTertiary.opacity(0.3))
                                            .frame(width: 28, height: 3)
                                    }
                                }
                            )

                        Text(selectedTab == "Home Screen" ? "Home Screen Widget" : "Lock Screen Widget")
                            .font(DesignTokens.Typography.bodyFont(14))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                )
        }
    }

    private var howToSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("How to add widget")
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            if selectedTab == "Home Screen" {
                stepRow(number: 1, text: "Long press on an empty area of your Home Screen until the apps start jiggling.")
                stepRow(number: 2, text: "Tap the \"+\" button in the top-left corner to open the widget gallery.")
                stepRow(number: 3, text: "Search for \"Qyra\" and select the widget size you prefer.")
                stepRow(number: 4, text: "Tap \"Add Widget\" and position it where you'd like on your Home Screen.")
            } else {
                stepRow(number: 1, text: "Long press on your Lock Screen and tap \"Customize\" at the bottom.")
                stepRow(number: 2, text: "Select the Lock Screen layout and tap the widget area below the time.")
                stepRow(number: 3, text: "Search for \"Qyra\" and choose a widget to add to your Lock Screen.")
            }
        }
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.buttonPrimary)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(DesignTokens.Typography.headlineFont(14))
                    .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
            }

            Text(text)
                .font(DesignTokens.Typography.bodyFont(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .lineSpacing(3)
        }
    }
}
