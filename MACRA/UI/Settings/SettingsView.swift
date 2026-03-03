import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                settingsRow(icon: "person.fill", title: "Profile")
                settingsRow(icon: "star.fill", title: "My Subscription")
            }

            Section("Health") {
                settingsRow(icon: "heart.fill", title: "Health Permissions")
                settingsRow(icon: "applewatch", title: "Apple Watch")
            }

            Section("Privacy") {
                settingsRow(icon: "lock.fill", title: "Privacy Controls")
                settingsRow(icon: "square.and.arrow.up", title: "Export Data")
            }

            Section("About") {
                settingsRow(icon: "doc.text", title: "Terms of Service")
                settingsRow(icon: "hand.raised.fill", title: "Privacy Policy")
                settingsRow(icon: "info.circle", title: "Version 1.0.0")
            }

            Section {
                Button(role: .destructive) {
                    // Phase 4: Sign out
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle("Settings")
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
