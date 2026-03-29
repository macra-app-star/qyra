import SwiftUI

struct GroupDetailView: View {
    let group: GroupModel
    let viewModel: GroupsViewModel

    @Environment(\.modelContext) private var modelContext
    @Environment(TabBarState.self) private var tabBarState
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Header
            headerSection

            // Tab selector — 4 tabs
            Picker("", selection: $selectedTab) {
                Text("Chat").tag(0)
                Text("Leaderboard").tag(1)
                Text("Members").tag(2)
                Text("Challenges").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DesignTokens.Spacing.md)

            // Tab content
            switch selectedTab {
            case 0:
                GroupChatView(messages: viewModel.messages, onSend: { text in
                    viewModel.sendMessage(text)
                })
            case 1:
                GroupLeaderboardView(entries: viewModel.leaderboard)
            case 2:
                GroupMembersView(group: group)
            case 3:
                GroupChallengesView(group: group)
            default:
                EmptyView()
            }
        }
        .background(DesignTokens.Colors.background)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { tabBarState.isVisible = false }
        .onDisappear { tabBarState.isVisible = true }
        .task {
            await viewModel.loadUserProfile(container: modelContext.container)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Avatar circle
            let firstLetter = String(group.name.prefix(1))
            let colorIndex = abs(group.name.hashValue) % DesignTokens.Colors.avatarColors.count
            let avatarColor = DesignTokens.Colors.avatarColors[colorIndex]

            Text(firstLetter)
                .font(DesignTokens.Typography.semibold(20))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(avatarColor)
                .clipShape(Circle())

            Text(group.name)
                .font(DesignTokens.Typography.headlineFont(20))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Text("\(group.memberCount) \(group.memberCount == 1 ? "member" : "members")")
                .font(DesignTokens.Typography.bodyFont(14))
                .foregroundStyle(DesignTokens.Colors.textSecondary)

            // Invite code pill
            Button {
                UIPasteboard.general.string = group.inviteCode
            } label: {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    Image(systemName: "doc.on.doc")
                        .font(DesignTokens.Typography.icon(12))
                    Text("Code: \(group.inviteCode)")
                        .font(DesignTokens.Typography.caption)
                }
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(DesignTokens.Colors.surface)
                .clipShape(Capsule())
            }
        }
        .padding(.top, DesignTokens.Spacing.sm)
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(
            group: {
                let g = GroupModel(name: "Fitness & Workouts")
                return g
            }(),
            viewModel: GroupsViewModel()
        )
    }
}
