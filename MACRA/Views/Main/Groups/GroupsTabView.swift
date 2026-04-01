import SwiftUI
import SwiftData

struct GroupsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GroupsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Action buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    actionButton(
                        title: "Create Group",
                        icon: "plus.circle.fill",
                        color: DesignTokens.Colors.brandAccent
                    ) {
                        viewModel.showCreateGroup = true
                    }

                    Button {
                        viewModel.showJoinAlert = true
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

                // My Groups section
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("My Groups")
                        .font(DesignTokens.Typography.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                        .padding(.horizontal, DesignTokens.Spacing.md)

                    if viewModel.groups.isEmpty {
                        emptyGroupsCard
                    } else {
                        ForEach(viewModel.groups) { group in
                            NavigationLink {
                                GroupDetailView(group: group, viewModel: viewModel)
                            } label: {
                                myGroupCard(group)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteGroup(group)
                                } label: {
                                    Label("Delete Group", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                // Discover section placeholder removed
            }
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.bottom, 80)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(DesignTokens.Colors.background)
        .navigationTitle("Groups")
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
        // MARK: - Create Group Sheet
        .sheet(isPresented: $viewModel.showCreateGroup) {
            createGroupSheet
        }
        // MARK: - Join Group Alert
        .alert("Join Group", isPresented: $viewModel.showJoinAlert) {
            TextField("Enter invite code", text: $viewModel.joinCode)
                .textInputAutocapitalization(.characters)
            Button("Join") {
                viewModel.joinGroup()
            }
            Button("Cancel", role: .cancel) {
                viewModel.joinCode = ""
            }
        } message: {
            Text("Enter the 6-character invite code to join a group.")
        }
        // MARK: - Created Success Alert
        .alert("Group Created", isPresented: $viewModel.showCreatedAlert) {
            Button("Copy Code") {
                if let code = viewModel.lastCreatedInviteCode {
                    UIPasteboard.general.string = code
                }
            }
            Button("OK", role: .cancel) {}
        } message: {
            if let code = viewModel.lastCreatedInviteCode {
                Text("Your invite code is \(code). Share it with friends to let them join!")
            }
        }
        // MARK: - Join Error Alert
        .alert("Could Not Join", isPresented: $viewModel.showJoinError) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.joinError {
                Text(error)
            }
        }
        // MARK: - Join Success Alert
        .alert("Joined Group", isPresented: $viewModel.showJoinSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You have joined \"\(viewModel.joinedGroupName)\".")
        }
    }

    // MARK: - Create Group Sheet

    private var createGroupSheet: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Group Name", text: $viewModel.newGroupName)
                        .textInputAutocapitalization(.words)
                        .onChange(of: viewModel.newGroupName) { _, newValue in
                            if newValue.count > 50 {
                                viewModel.newGroupName = String(newValue.prefix(50))
                            }
                        }
                } header: {
                    Text("Name")
                } footer: {
                    Text("\(viewModel.newGroupName.count)/50 characters")
                        .font(.caption)
                        .foregroundStyle(viewModel.newGroupName.count > 50 ? .red : Color(.tertiaryLabel))
                }

                Section {
                    Toggle("Private Group", isOn: $viewModel.newGroupIsPrivate)
                        .tint(.accentColor)
                } header: {
                    Text("Privacy")
                } footer: {
                    Text(viewModel.newGroupIsPrivate
                         ? "Only people with the invite code can join."
                         : "Anyone can discover and join this group.")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.newGroupName = ""
                        viewModel.newGroupIsPrivate = true
                        viewModel.showCreateGroup = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createGroup()
                        viewModel.showCreateGroup = false
                    }
                    .fontWeight(.semibold)
                    .disabled({
                        let trimmed = viewModel.newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                        return trimmed.isEmpty || trimmed.count > 50
                    }())
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Action Button

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

    // MARK: - Empty Groups Card

    private var emptyGroupsCard: some View {
        EmptyDataView(
            title: "No Groups",
            subtitle: "Create a group or join one with an invite code."
        )
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        .padding(.horizontal, DesignTokens.Spacing.md)
    }

    // MARK: - My Group Card

    private func myGroupCard(_ group: GroupModel) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            let firstLetter = String(group.name.prefix(1))
            let colorIndex = abs(group.name.hashValue) % DesignTokens.Colors.avatarColors.count
            let avatarColor = DesignTokens.Colors.avatarColors[colorIndex]

            Text(firstLetter)
                .font(DesignTokens.Typography.semibold(16))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(avatarColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                Text(group.name)
                    .font(DesignTokens.Typography.headline)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                HStack(spacing: DesignTokens.Spacing.xs) {
                    Text("\(group.memberCount.formatted()) \(group.memberCount == 1 ? "member" : "members")")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text("  \(group.isPrivate ? "Private" : "Public")")
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(DesignTokens.Typography.icon(14))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }

}

#Preview {
    NavigationStack {
        GroupsTabView()
    }
    .modelContainer(for: GroupModel.self, inMemory: true)
}
