import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var showSignOutConfirmation = false

    private let termsURL = URL(string: "https://macra-app-star.github.io/macra-landing/terms.html")!
    private let privacyURL = URL(string: "https://macra-app-star.github.io/macra-landing/privacy.html")!

    var body: some View {
        List {
            Section("Account") {
                NavigationLink {
                    ProfileEditorView()
                } label: {
                    settingsLabel(icon: "person.fill", title: "Profile")
                }

                NavigationLink {
                    MySubscriptionView()
                } label: {
                    settingsLabel(icon: "star.fill", title: "My Subscription")
                }
            }

            Section("Nutrition") {
                NavigationLink {
                    GoalEditorView()
                } label: {
                    settingsLabel(icon: "target", title: "Macro Goals")
                }
            }

            Section("Health") {
                NavigationLink {
                    HealthPermissionsView()
                } label: {
                    settingsLabel(icon: "heart.fill", title: "Health Permissions")
                }
            }

            Section("Data") {
                NavigationLink {
                    DataExportView()
                } label: {
                    settingsLabel(icon: "square.and.arrow.up", title: "Export Data")
                }
            }

            Section("About") {
                NavigationLink {
                    WebContentView(title: "Terms of Service", url: termsURL)
                } label: {
                    settingsLabel(icon: "doc.text", title: "Terms of Service")
                }

                NavigationLink {
                    WebContentView(title: "Privacy Policy", url: privacyURL)
                } label: {
                    settingsLabel(icon: "hand.raised.fill", title: "Privacy Policy")
                }

                settingsRow(icon: "info.circle", title: "Version 1.0.0")
            }

            Section {
                Button(role: .destructive) {
                    showSignOutConfirmation = true
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
        .alert("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                appState.signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private func settingsLabel(icon: String, title: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .frame(width: 24)

            Text(title)
                .font(DesignTokens.Typography.body)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
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
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AppState())
}
