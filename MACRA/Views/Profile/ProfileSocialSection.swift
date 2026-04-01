import SwiftUI

struct ProfileSocialSection: View {
    private let socials: [(name: String, icon: String, urlString: String)] = [
        ("Instagram", "camera.fill", "https://instagram.com/qyra.app"),
        ("TikTok", "play.rectangle.fill", "https://tiktok.com/@qyra.app"),
        ("X", "at", "https://twitter.com/qyra_app"),
    ]

    var body: some View {
        Section {
            ForEach(socials, id: \.name) { social in
                Button {
                    if let url = URL(string: social.urlString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Label(social.name, systemImage: social.icon)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
        } header: {
            Text("Follow Us")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .textCase(nil)
        }
    }
}

#Preview {
    List {
        ProfileSocialSection()
    }
    .listStyle(.insetGrouped)
}
