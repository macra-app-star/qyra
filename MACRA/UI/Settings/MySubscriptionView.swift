import SwiftUI
import StoreKit

struct MySubscriptionView: View {
    @State private var subscriptionService = SubscriptionService()
    @State private var subscriptionInfo: SubscriptionInfo?
    @State private var isLoading = true

    var body: some View {
        List {
            Section("Current Plan") {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(DesignTokens.Colors.textSecondary)
                        Spacer()
                    }
                } else if let info = subscriptionInfo {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        HStack {
                            Text(productDisplayName(info.productID))
                                .font(DesignTokens.Typography.headline)
                                .foregroundStyle(DesignTokens.Colors.textPrimary)

                            Spacer()

                            statusBadge
                        }

                        if let expiration = info.expirationDate {
                            Text("Renews \(expiration.formatted(date: .abbreviated, time: .omitted))")
                                .font(DesignTokens.Typography.footnote)
                                .foregroundStyle(DesignTokens.Colors.textTertiary)
                        }
                    }
                } else {
                    Text("No active subscription")
                        .font(DesignTokens.Typography.body)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Section {
                Button {
                    Task {
                        if let windowScene = UIApplication.shared.connectedScenes
                            .compactMap({ $0 as? UIWindowScene })
                            .first {
                            try? await AppStore.showManageSubscriptions(in: windowScene)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 24)

                        Text("Manage Subscription")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.forward.square")
                            .font(.system(size: 12))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }

            Section(footer: Text("Subscriptions are managed through Apple. Changes may take a moment to reflect.")) {
                Button {
                    Task {
                        isLoading = true
                        try? await subscriptionService.restorePurchases()
                        subscriptionInfo = await subscriptionService.currentSubscription
                        isLoading = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .frame(width: 24)

                        Text("Refresh Status")
                            .font(DesignTokens.Typography.body)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(DesignTokens.Colors.background)
        .navigationTitle("My Subscription")
        .task {
            subscriptionInfo = await subscriptionService.currentSubscription
            isLoading = false
        }
    }

    // MARK: - Helpers

    private var statusBadge: some View {
        Text("Active")
            .font(DesignTokens.Typography.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.black)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xxs)
            .background(Color.white)
            .clipShape(Capsule())
    }

    private func productDisplayName(_ productID: String) -> String {
        switch productID {
        case "macra.monthly": return "MACRA Monthly"
        case "macra.yearly": return "MACRA Yearly"
        default: return "MACRA Premium"
        }
    }
}

#Preview {
    NavigationStack {
        MySubscriptionView()
    }
}
