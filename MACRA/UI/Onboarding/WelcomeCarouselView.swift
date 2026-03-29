import SwiftUI

struct WelcomeCarouselView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var currentPage: Int = 0
    private let pageCount = 3

    var body: some View {
        ZStack {
            OnboardingTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top-right language badge
                HStack {
                    Spacer()

                    Text("\u{1F1FA}\u{1F1F8} EN")
                        .font(QyraFont.medium(13))
                        .foregroundStyle(OnboardingTheme.textPrimary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, DesignTokens.Layout.itemGap)
                        .background(OnboardingTheme.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Layout.smallCardCornerRadius))
                }
                .padding(.trailing, DesignTokens.Spacing.lg)
                .padding(.top, DesignTokens.Layout.itemGap)

                Spacer()

                // Phone mockup
                PhoneMockupView()

                // Page indicators
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        if index == currentPage {
                            // Active pill
                            RoundedRectangle(cornerRadius: 3)
                                .fill(OnboardingTheme.textPrimary)
                                .frame(width: 20, height: 6)
                        } else {
                            // Inactive dot
                            Circle()
                                .fill(OnboardingTheme.progressEmpty)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                .animation(OnboardingTheme.quickSpring, value: currentPage)
                .padding(.top, DesignTokens.Spacing.lg)

                // Title
                OnboardingTitle(
                    text: "Nutrition intelligence made effortless",
                    alignment: .center
                )
                .padding(.top, DesignTokens.Spacing.lg)

                Spacer()

                // Primary CTA
                OnboardingContinueButton(label: "Get Started", isEnabled: true) {
                    viewModel.advance()
                }

                // Secondary CTA
                HStack(spacing: 0) {
                    Text("Already have an account? ")
                        .font(QyraFont.regular(15))
                        .foregroundStyle(OnboardingTheme.textSecondary)

                    Button {
                        viewModel.showSignInSheet = true
                    } label: {
                        Text("Sign In")
                            .font(QyraFont.bold(15))
                            .foregroundStyle(OnboardingTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, -24) // Offset to sit 8pt below the CTA's bottom padding
                .padding(.bottom, DesignTokens.Spacing.lg)
            }
        }
        .onReceive(
            Timer.publish(every: 3, on: .main, in: .common).autoconnect()
        ) { _ in
            currentPage = (currentPage + 1) % pageCount
        }
    }
}

#Preview {
    WelcomeCarouselView(viewModel: .preview)
}
