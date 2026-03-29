import SwiftUI

struct WearableSettingsView: View {
    var body: some View {
        ScrollView {
            WearableConnectionView(isOnboarding: false)
                .padding(.top, 16)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Connected Devices")
    }
}

#Preview {
    NavigationStack {
        WearableSettingsView()
    }
}
