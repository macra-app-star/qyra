import SwiftUI

struct PremiumGateView: View {
    let featureName: String
    let icon: String
    @Binding var showPaywall: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(featureName)
                .font(.title2.weight(.bold))

            Text("Unlock this feature with Qyra Pro")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showPaywall = true
            } label: {
                Text("View Plans")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
            .padding(.horizontal, 48)

            #if DEBUG
            Button {
                // Dev bypass — simulate subscription
                UserDefaults.standard.set(true, forKey: "devBypassSubscription")
                NotificationCenter.default.post(name: Notification.Name("devSubscriptionBypassed"), object: nil)
            } label: {
                Text("Skip (Dev)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 8)
            #endif

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    PremiumGateView(
        featureName: "Cycle",
        icon: "waveform.path.ecg",
        showPaywall: .constant(false)
    )
}
