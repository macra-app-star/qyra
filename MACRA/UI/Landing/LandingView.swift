import SwiftUI

struct LandingView: View {
    @Environment(AppState.self) private var appState
    @State private var showSignIn = false

    // Entrance animation states
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            // Qyra. logo — top
            Text("Qyra.")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 72)
                .offset(y: showLogo ? 0 : 20)
                .opacity(showLogo ? 1 : 0)

            Spacer()

            // 3-line tagline — centered
            VStack(spacing: 6) {
                Text("Know your body.")
                    .font(QyraFont.bold(34))
                    .foregroundStyle(DesignTokens.Colors.ink)

                Text("Own your health.")
                    .font(QyraFont.bold(34))
                    .foregroundStyle(DesignTokens.Colors.ink)

                Text("Start today.")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color(hex: "6E6E73"))
            }
            .multilineTextAlignment(.center)
            .offset(y: showTagline ? 0 : 20)
            .opacity(showTagline ? 1 : 0)

            Spacer()

            // Get Started button
            Button {
                appState.gateStatus = .needsOnboarding
            } label: {
                Text("Get Started")
                    .font(QyraFont.semibold(17))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 56)
                    .background(Color(.label))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 16)
            .opacity(showButton ? 1 : 0)

            // Sign In link
            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(Color(hex: "6E6E73"))

                Button {
                    showSignIn = true
                } label: {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.label))
                }
            }
            .font(QyraFont.regular(15))
            .padding(.top, 16)
            .padding(.bottom, 32)
            .opacity(showButton ? 1 : 0)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showLogo = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                showTagline = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                showButton = true
            }
        }
        .sheet(isPresented: $showSignIn) {
            SignInView()
                .presentationDetents([.fraction(0.48)])
                .presentationDragIndicator(.hidden)
                .presentationCornerRadius(24)
        }
    }
}

#Preview {
    LandingView()
        .environment(AppState())
}
