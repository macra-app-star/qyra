import SwiftUI

struct HealthPermissionsView: View {
    @State private var isAuthorized = false
    @State private var isRequesting = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Qyra can read your step count and active calories from Apple Health to show your daily activity on the dashboard.")
                        .font(DesignTokens.Typography.callout)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                .padding(.vertical, DesignTokens.Spacing.xs)
            }

            Section("Permissions") {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 24)
                    Text("Step Count")
                        .font(DesignTokens.Typography.body)
                    Spacer()
                    statusBadge
                }

                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                        .frame(width: 24)
                    Text("Active Energy")
                        .font(DesignTokens.Typography.body)
                    Spacer()
                    statusBadge
                }
            }

            Section {
                Button {
                    Task {
                        isRequesting = true
                        let result = await HealthKitService.shared.requestAuthorization()
                        isAuthorized = result
                        isRequesting = false
                    }
                } label: {
                    HStack {
                        Spacer()
                        if isRequesting {
                            ProgressView()
                        } else {
                            Text(isAuthorized ? "Permissions Granted" : "Grant Access")
                        }
                        Spacer()
                    }
                }
                .disabled(isAuthorized || isRequesting)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle("Health Permissions")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusBadge: some View {
        Text(isAuthorized ? "Enabled" : "Not Set")
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(isAuthorized ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textTertiary)
    }
}

#Preview {
    NavigationStack {
        HealthPermissionsView()
    }
}
