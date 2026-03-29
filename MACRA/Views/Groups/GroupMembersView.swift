import SwiftUI

struct GroupMembersView: View {
    let group: GroupModel

    // Mock data — will connect to Supabase
    private let members: [(name: String, role: String, initials: String, color: Color)] = [
        ("You", "Host", "ME", .blue),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.sm) {
                // Member count header
                HStack {
                    Text("\(group.memberCount) \(group.memberCount == 1 ? "Member" : "Members")")
                        .font(.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                    Button {
                        // Invite members
                    } label: {
                        Label("Invite", systemImage: "person.badge.plus")
                            .font(.subheadline.weight(.medium))
                    }
                    .tint(.accentColor)
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)

                // Members list
                ForEach(Array(members.enumerated()), id: \.offset) { _, member in
                    memberRow(name: member.name, role: member.role, initials: member.initials, color: member.color)
                }

                // Invite code card
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Invite Code")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                    Text(group.inviteCode)
                        .font(.title3.weight(.bold).monospaced())
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("Share this code with friends to join")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(DesignTokens.Spacing.lg)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)
            }
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
    }

    private func memberRow(name: String, role: String, initials: String, color: Color) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 44, height: 44)
                Text(initials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Name + role
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                Text(role)
                    .font(.caption)
                    .foregroundStyle(role == "Host" ? .orange : DesignTokens.Colors.textSecondary)
            }

            Spacer()

            if role == "Host" {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

#Preview {
    GroupMembersView(group: GroupModel(name: "Test Group", isPrivate: false))
}
