import SwiftUI

struct SplashView: View {
    @Bindable var viewModel: OnboardingViewModel

    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            Text("Qyra.")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .opacity(opacity)
        }
        .onAppear {
            // Hold for 1.2s, then fade out over 0.4s, then advance
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    opacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    viewModel.navigateTo(.nameEntry)
                }
            }
        }
    }
}

#Preview {
    SplashView(viewModel: .preview)
}
