import SwiftUI
import SwiftData

struct ProfileEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var ageText = ""
    @State private var gender = "Not specified"
    @State private var isLoading = true

    private let genderOptions = ["Male", "Female", "Non-binary", "Not specified"]

    var body: some View {
        Form {
            Section("Personal") {
                TextField("Display Name", text: $displayName)
                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }

            Section("Body") {
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("lbs")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .frame(width: 30, alignment: .leading)
                }

                HStack {
                    Text("Height")
                    Spacer()
                    TextField("0", text: $heightText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("in")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .frame(width: 30, alignment: .leading)
                }

                HStack {
                    Text("Age")
                    Spacer()
                    TextField("0", text: $ageText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("yrs")
                        .foregroundStyle(DesignTokens.Colors.textTertiary)
                        .frame(width: 30, alignment: .leading)
                }
            }

            Section("Account") {
                if let name = AuthService.shared.currentUserName {
                    HStack {
                        Text("Apple ID Name")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text(name)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }

                if let userId = AuthService.shared.currentUserId {
                    HStack {
                        Text("User ID")
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                        Spacer()
                        Text(String(userId.prefix(8)) + "...")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task { await saveProfile() }
                }
            }
        }
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        let repo = ProfileRepository(modelContainer: modelContext.container)
        if let snapshot = try? await repo.fetchProfileSnapshot() {
            displayName = snapshot.displayName ?? ""
            if snapshot.weight > 0 { weightText = String(format: "%.0f", snapshot.weight) }
            if snapshot.height > 0 { heightText = String(format: "%.0f", snapshot.height) }
            if snapshot.age > 0 { ageText = "\(snapshot.age)" }
            gender = snapshot.gender ?? "Not specified"
        }
        isLoading = false
    }

    private func saveProfile() async {
        let weightLbs = Double(weightText) ?? 0
        let heightIn = Double(heightText) ?? 0
        let weightKg = weightLbs > 0 ? weightLbs / 2.20462 : nil as Double?
        let heightCm = heightIn > 0 ? heightIn * 2.54 : nil as Double?
        let age = Int(ageText)

        let repo = ProfileRepository(modelContainer: modelContext.container)
        try? await repo.saveProfile(
            displayName: displayName.isEmpty ? nil : displayName,
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: gender == "Not specified" ? nil : gender
        )
        DesignTokens.Haptics.success()
        dismiss()
    }
}
