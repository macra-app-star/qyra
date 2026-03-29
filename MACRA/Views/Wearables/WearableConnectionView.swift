import SwiftUI

struct WearableConnectionView: View {
    @State private var wearableService = WearableService.shared
    @State private var expandedProvider: WearableProvider?
    let isOnboarding: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isOnboarding {
                headerSection
            }

            providerList

            if isOnboarding {
                Text("You can always connect devices later in Settings.")
                    .font(QyraFont.footnote)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, DesignTokens.Layout.sectionHorizontalPadding)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Connect your devices")
                .font(QyraFont.bold(32))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("Qyra syncs with your wearables for a complete picture of your health.")
                .font(QyraFont.regular(16))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
    }

    private var providerList: some View {
        VStack(spacing: 12) {
            ForEach(WearableProvider.allCases) { provider in
                providerCard(for: provider)
            }
        }
    }

    private func providerCard(for provider: WearableProvider) -> some View {
        let state = wearableService.connectionStates[provider] ?? .disconnected
        let lastSync = wearableService.lastSyncTimes[provider]
        let isExpanded = expandedProvider == provider

        return WearableProviderCard(
            provider: provider,
            state: state,
            lastSync: lastSync,
            isExpanded: isExpanded,
            onConnect: {
                Task { await wearableService.connect(provider) }
            },
            onDisconnect: {
                wearableService.disconnect(provider)
            },
            onTap: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedProvider = isExpanded ? nil : provider
                }
            }
        )
    }
}

// MARK: - Provider Card

struct WearableProviderCard: View {
    let provider: WearableProvider
    let state: WearableService.ConnectionState
    let lastSync: Date?
    let isExpanded: Bool
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(cardBackground)
    }

    private var mainRow: some View {
        HStack(spacing: 16) {
            providerIcon
            providerInfo
            Spacer()
            connectionButton
        }
        .padding(DesignTokens.Layout.cardInternalPadding)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var providerIcon: some View {
        ZStack {
            Circle()
                .fill(provider.brandColor.opacity(0.1))
                .frame(width: 48, height: 48)
            Image(systemName: provider.iconName)
                .font(DesignTokens.Typography.icon(20))
                .foregroundStyle(provider.brandColor)
        }
    }

    private var providerInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(provider.displayName)
                .font(QyraFont.semibold(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text(statusText)
                .font(QyraFont.caption1)
                .foregroundStyle(statusColor)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    // MARK: - Expanded Section

    @ViewBuilder
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .padding(.horizontal, DesignTokens.Layout.cardInternalPadding)

            Text("Data available")
                .font(QyraFont.caption1)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, DesignTokens.Layout.cardInternalPadding)
                .padding(.top, 8)

            dataTypeTags

            if state == .connected {
                connectedDetails
            }

            Spacer().frame(height: 16)
        }
    }

    private var dataTypeTags: some View {
        FlowLayout(spacing: 8) {
            ForEach(provider.dataTypes, id: \.self) { type in
                Text(type.displayName)
                    .font(QyraFont.caption1)
                    .padding(.horizontal, DesignTokens.Layout.itemGap)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(DesignTokens.Colors.background))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DesignTokens.Layout.cardInternalPadding)
    }

    @ViewBuilder
    private var connectedDetails: some View {
        if let lastSync {
            Text("Last synced \(lastSync.formatted(.relative(presentation: .named)))")
                .font(QyraFont.micro)
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .padding(.horizontal, DesignTokens.Layout.cardInternalPadding)
                .padding(.top, 4)
        }

        Button {
            onDisconnect()
        } label: {
            Text("Disconnect")
                .font(QyraFont.medium(14))
                .foregroundStyle(DesignTokens.Colors.destructive)
        }
        .padding(.horizontal, DesignTokens.Layout.cardInternalPadding)
        .padding(.top, 4)
    }

    // MARK: - Connection Button

    @ViewBuilder
    private var connectionButton: some View {
        switch state {
        case .disconnected:
            Button(action: onConnect) {
                Text("Connect")
                    .font(QyraFont.medium(14))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentColor))
            }
            .buttonStyle(.plain)
        case .connecting:
            ProgressView()
                .tint(DesignTokens.Colors.accent)
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(hex: "34C759"))
        case .error:
            Button(action: onConnect) {
                Text("Retry")
                    .font(QyraFont.medium(14))
                    .foregroundStyle(DesignTokens.Colors.accent)
            }
        }
    }

    // MARK: - Helpers

    private var statusText: String {
        switch state {
        case .disconnected: return "Not connected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        case .error(let msg): return msg
        }
    }

    private var statusColor: Color {
        switch state {
        case .connected: return Color(hex: "34C759")
        case .error: return Color(hex: "FF3B30")
        default: return DesignTokens.Colors.textSecondary
        }
    }
}

#Preview {
    ScrollView {
        WearableConnectionView(isOnboarding: true)
    }
    .background(DesignTokens.Colors.background)
}
