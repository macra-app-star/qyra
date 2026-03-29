import SwiftUI

struct ProfileSupportSection: View {
    @State private var isSyncing = false
    @State private var lastSynced: Date? = SupabaseAPIService.lastSyncDate

    var body: some View {
        Section {
            NavigationLink {
                DataExportView()
            } label: {
                Label("Export PDF Summary Report", systemImage: "doc.richtext")
            }

            Button {
                guard !isSyncing else { return }
                isSyncing = true
                Task {
                    // Trigger a sync — update timestamp on success
                    await MainActor.run {
                        UserDefaults.standard.set(Date(), forKey: SupabaseAPIService.lastSyncDateKey)
                        lastSynced = SupabaseAPIService.lastSyncDate
                        isSyncing = false
                    }
                }
            } label: {
                HStack {
                    Label("Sync Data", systemImage: "arrow.triangle.2.circlepath")
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                    if isSyncing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text(lastSyncedText)
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            NavigationLink {
                WebContentView(
                    title: "Terms and Conditions",
                    url: URL(string: "https://macra-app-star.github.io/macra-landing/terms.html")!
                )
            } label: {
                Label("Terms and Conditions", systemImage: "doc.text")
            }

            NavigationLink {
                WebContentView(
                    title: "Privacy Policy",
                    url: URL(string: "https://macra-app-star.github.io/macra-landing/privacy.html")!
                )
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised.fill")
            }

            NavigationLink {
                MySubscriptionView()
            } label: {
                Label("Manage Subscription", systemImage: "star.fill")
            }
        }
    }

    private var lastSyncedText: String {
        guard let lastSynced else { return "Never" }
        return "Last Synced: \(lastSynced.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))"
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileSupportSection()
        }
        .listStyle(.insetGrouped)
    }
}
