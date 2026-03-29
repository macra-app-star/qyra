import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("No notifications")
                    .font(.headline)

                Text("You're all caught up!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NotificationsView()
}
