import SwiftUI
import SwiftData

struct ProfileActionsSection: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showDeleteError = false

    var body: some View {
        Section {
            Button {
                showSignOutAlert = true
            } label: {
                HStack {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }

            Button {
                showDeleteAlert = true
            } label: {
                HStack {
                    Label("Delete Account", systemImage: "trash")
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                    if isDeleting {
                        ProgressView()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
            .disabled(isDeleting)
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task { await performAccountDeletion() }
                }
            } message: {
                Text("This action is permanent and cannot be undone. All your data will be deleted.")
            }
            .alert("Delete Failed", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteError ?? "An unexpected error occurred. Please try again.")
            }
        } header: {
            Text("Account Actions")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .textCase(.uppercase)
        }
    }

    private func performAccountDeletion() async {
        isDeleting = true
        defer { isDeleting = false }

        // Delete server-side data first
        do {
            try await SupabaseAPIService.shared.deleteAccount()
        } catch {
            deleteError = error.localizedDescription
            showDeleteError = true
            return
        }

        // Clear local data
        do {
            try modelContext.delete(model: MealLog.self)
            try modelContext.delete(model: MealItem.self)
            try modelContext.delete(model: ExerciseEntry.self)
            try modelContext.delete(model: WaterEntry.self)
            try modelContext.delete(model: WeightEntry.self)
            try modelContext.delete(model: UserProfile.self)
            try modelContext.delete(model: MacroGoal.self)
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to delete local account data: \(error)")
            #endif
        }

        appState.signOut()
    }
}

#Preview {
    List {
        ProfileActionsSection()
    }
    .listStyle(.insetGrouped)
    .environment(AppState())
}
