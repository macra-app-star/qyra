import SwiftUI

struct ProfileInviteSection: View {
    @State private var showShareSheet = false

    var body: some View {
        Section {
            Button {
                showShareSheet = true
            } label: {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                        .foregroundStyle(DesignTokens.Colors.accent)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Share Qyra")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text("Invite friends to track macros together")
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
        } header: {
            Text("Invite Friends")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .textCase(nil)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: ["Check out Qyra — a smart nutrition tracker that actually works. https://apps.apple.com/app/qyra"])
        }
    }
}

#Preview {
    List {
        ProfileInviteSection()
    }
    .listStyle(.insetGrouped)
}
