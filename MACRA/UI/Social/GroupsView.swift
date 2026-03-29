import SwiftUI

struct GroupsView: View {
    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var joinCode = ""

    // Pre-seeded public groups for discovery
    private let discoveryGroups: [(name: String, members: Int, icon: String)] = [
        ("Fitness & Workouts", 1243, "figure.run"),
        ("Weight Loss Support", 892, "scalemass.fill"),
        ("Meal Prep Ideas", 567, "fork.knife"),
        ("Protein Goals", 431, "bolt.fill"),
        ("Macro Beginners", 756, "graduationcap.fill"),
        ("Clean Eating", 324, "leaf.fill"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Action buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    actionButton(title: "Create Group", icon: "plus.circle.fill", color: DesignTokens.Colors.brandAccent) {
                        showCreateGroup = true
                    }
                    Button {
                        showJoinGroup = true
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "person.badge.plus")
                                .font(DesignTokens.Typography.icon(18))
                            Text("Join Group")
                                .font(DesignTokens.Typography.headline)
                        }
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.accentColor.opacity(0.12))
                        )
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)

                // My Groups Section
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("My Groups")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    emptyGroupsCard
                }

                // Public groups placeholder
                Text("Public groups coming soon.")
                    .font(.subheadline)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DesignTokens.Colors.background)
        .navigationTitle("Groups")
        .alert("Join Group", isPresented: $showJoinGroup) {
            TextField("Enter invite code", text: $joinCode)
            Button("Join") {
                // Join group logic
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter the 6-character invite code to join a group.")
        }
    }

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: icon)
                    .font(DesignTokens.Typography.icon(18))
                Text(title)
                    .font(DesignTokens.Typography.headline)
            }
            .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private var emptyGroupsCard: some View {
        EmptyDataView(
            title: "No Groups",
            subtitle: "Create a group or join one with an invite code.",
            actionTitle: "Create Group",
            action: { showCreateGroup = true }
        )
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    private func discoveryCard(name: String, members: Int, icon: String) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: icon)
                .font(DesignTokens.Typography.icon(24))
                .foregroundStyle(DesignTokens.Colors.brandAccent)
                .frame(width: 44, height: 44)
                .background(DesignTokens.Colors.brandAccent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(name)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("\(members.formatted()) members")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Colors.textSecondary)
            }

            Spacer()

            Button {
            } label: {
                Text("Join")
                    .font(DesignTokens.Typography.label(14))
                    .foregroundStyle(DesignTokens.Colors.buttonPrimaryText)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.brandAccent)
                    .clipShape(Capsule())
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
}

#Preview {
    NavigationStack {
        GroupsView()
    }
}
