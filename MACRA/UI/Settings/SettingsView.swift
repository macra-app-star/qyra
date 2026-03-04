import SwiftUI

struct SettingsView: View {
    @State private var showComingSoon = false
    @State private var comingSoonFeature = ""

    var body: some View {
        List {
            Section("Account") {
                comingSoonRow(icon: "person.fill", title: "Profile", feature: "Profile editing")
                NavigationLink {
                    MySubscriptionView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 24)

                        Text("My Subscription")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                }
            }

            Section("Nutrition") {
                NavigationLink {
                    GoalEditorView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "target")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 24)

                        Text("Macro Goals")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                }
            }

            Section("Health") {
                NavigationLink {
                    HealthPermissionsView()
                } label: {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 24)

                        Text("Health Permissions")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                }
                comingSoonRow(icon: "applewatch", title: "Apple Watch", feature: "Apple Watch companion")
            }

            Section("Privacy") {
                comingSoonRow(icon: "lock.fill", title: "Privacy Controls", feature: "Privacy controls")
                comingSoonRow(icon: "square.and.arrow.up", title: "Export Data", feature: "Data export")
            }

            Section("About") {
                comingSoonRow(icon: "doc.text", title: "Terms of Service", feature: "Terms of Service")
                comingSoonRow(icon: "hand.raised.fill", title: "Privacy Policy", feature: "Privacy Policy")
                settingsRow(icon: "info.circle", title: "Version 1.0.0")
            }

            Section {
                Button(role: .destructive) {
                    // Future: Sign out
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
        .alert(comingSoonFeature, isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(comingSoonFeature) is coming in a future update.")
        }
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
        }
    }

    private func comingSoonRow(icon: String, title: String, feature: String) -> some View {
        Button {
            comingSoonFeature = feature
            showComingSoon = true
        } label: {
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
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
