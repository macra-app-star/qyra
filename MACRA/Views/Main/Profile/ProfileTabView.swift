import SwiftUI
import SwiftData

struct ProfileTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProfileViewModel()
    @State private var healthKitAuthorized = false

    var body: some View {
        List {
            // 1. Profile Card
            Section {
                ProfileUserCard(viewModel: viewModel)
            }

            // 2. Invite Friends
            ProfileInviteSection()

            // 3. Account
            ProfileAccountSection()

            // 4. Goals & Tracking
            ProfileGoalsSection(healthKitAuthorized: $healthKitAuthorized)

            // 5. Widgets
            Section {
                ProfileWidgetsSection()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // 6. More rows (no header)
            ProfileSupportSection()

            // 7. Follow Us
            ProfileSocialSection()

            // 8. Account Actions
            ProfileActionsSection()
        }
        .contentMargins(.bottom, 80)
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.load(container: modelContext.container)
            healthKitAuthorized = HealthKitService.shared.hasBeenAuthorized
        }
    }
}

#Preview {
    NavigationStack {
        ProfileTabView()
    }
}
