import SwiftUI

struct SocialView: View {
    var body: some View {
        ZStack {
            DesignTokens.Colors.background
                .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(DesignTokens.Colors.textSecondary)

                Text("Friends & Leaderboard")
                    .font(DesignTokens.Typography.title2)
                    .foregroundStyle(DesignTokens.Colors.textPrimary)

                Text("Connect with friends and track progress together")
                    .font(DesignTokens.Typography.callout)
                    .foregroundStyle(DesignTokens.Colors.textTertiary)
                    .multilineTextAlignment(.center)

                MonochromeButton("Add Friends", icon: "person.badge.plus", style: .primary) {}
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
        }
        .navigationTitle("Social")
    }
}

#Preview {
    NavigationStack {
        SocialView()
    }
}
