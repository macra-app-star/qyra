import SwiftUI

struct ProfileAccountSection: View {
    var body: some View {
        Section {
            NavigationLink {
                PersonalDetailsView()
            } label: {
                Label("Personal Details", systemImage: "list.clipboard")
            }

            NavigationLink {
                PreferencesView()
            } label: {
                Label("Preferences", systemImage: "gearshape")
            }

            // Language placeholder
            NavigationLink {
                Text("Language settings coming soon")
                    .navigationTitle("Language")
            } label: {
                Label("Language", systemImage: "globe")
            }

            // Family Plan hidden until ready
            // NavigationLink {
            //     FamilyPlanView()
            // } label: {
            //     Label("Upgrade to Family Plan", systemImage: "person.2")
            // }
        } header: {
            Text("Account")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .textCase(.uppercase)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileAccountSection()
        }
        .listStyle(.insetGrouped)
    }
}
