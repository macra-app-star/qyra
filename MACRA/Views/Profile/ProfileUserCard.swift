import SwiftUI

struct ProfileUserCard: View {
    let viewModel: ProfileViewModel

    var body: some View {
        NavigationLink {
            ProfileEditorView()
        } label: {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Avatar
                if let photo = viewModel.profilePhoto {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.brandAccent)
                            .frame(width: 56, height: 56)

                        if viewModel.avatarInitials.isEmpty {
                            Image(systemName: "person.fill")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        } else {
                            Text(viewModel.avatarInitials)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                // Name, premium badge, username
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium")
                        .font(DesignTokens.Typography.medium(11))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    Text(viewModel.displayName)
                        .font(.body.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)

                    if let username = usernameDisplay {
                        Text(username)
                            .font(DesignTokens.Typography.medium(13))
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    } else {
                        Text("Set a username")
                            .font(DesignTokens.Typography.medium(13))
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
        }
    }

    private var usernameDisplay: String? {
        // Check for stored username from onboarding
        if let stored = UserDefaults.standard.string(forKey: "username"), !stored.isEmpty {
            return "@\(stored)"
        }
        if !viewModel.email.isEmpty {
            let name = viewModel.email.components(separatedBy: "@").first ?? ""
            if !name.isEmpty { return "@\(name)" }
        }
        let name = viewModel.displayName.lowercased().replacingOccurrences(of: " ", with: "")
        if !name.isEmpty { return "@\(name)" }
        return nil
    }
}

#Preview {
    NavigationStack {
        List {
            Section {
                ProfileUserCard(viewModel: {
                    let vm = ProfileViewModel()
                    vm.displayName = "Benjamin Tamras"
                    vm.email = "ben@qyra.app"
                    vm.avatarInitials = "BT"
                    return vm
                }())
            }
        }
        .listStyle(.insetGrouped)
    }
}
