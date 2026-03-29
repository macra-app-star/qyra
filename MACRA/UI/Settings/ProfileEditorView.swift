import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct ProfileEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var displayName = ""
    @State private var weightLbs: Int = 150
    @State private var heightInches: Int = 68
    @State private var age: Int = 25
    @State private var showWeightPicker = false
    @State private var showHeightPicker = false
    @State private var showAgePicker = false
    @State private var gender = "Not specified"
    @State private var isLoading = true
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    private let genderOptions = ["Male", "Female", "Non-binary", "Not specified"]

    var body: some View {
        Form {
            // Profile Photo
            Section {
                VStack(spacing: DesignTokens.Spacing.md) {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.brandAccent)
                                .frame(width: 80, height: 80)

                            if displayName.isEmpty {
                                Image(systemName: "person.fill")
                                    .font(.title.weight(.semibold))
                                    .foregroundStyle(.white)
                            } else {
                                let words = displayName.split(separator: " ").map(String.init)
                                let initials: String = {
                                    if words.count >= 2 {
                                        return (String(words[0].prefix(1)) + String(words[1].prefix(1))).uppercased()
                                    } else if let first = words.first, !first.isEmpty {
                                        return String(first.prefix(2)).uppercased()
                                    }
                                    return ""
                                }()
                                Text(initials)
                                    .font(.title.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Text("Change Photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    guard let newValue else { return }
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data),
                       let compressed = uiImage.jpegData(compressionQuality: 0.7) {
                        profileImage = UIImage(data: compressed)
                        let repo = ProfileRepository(modelContainer: modelContext.container)
                        try? await repo.saveProfilePhoto(compressed)
                    }
                }
            }

            Section("Personal") {
                TextField("Display Name", text: $displayName)
                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
            }

            Section("Body") {
                // Weight
                Button {
                    withAnimation { showWeightPicker.toggle(); showHeightPicker = false; showAgePicker = false }
                } label: {
                    HStack {
                        Text("Weight")
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Text("\(weightLbs) lbs")
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                    }
                }
                if showWeightPicker {
                    Picker("Weight", selection: $weightLbs) {
                        ForEach(80...400, id: \.self) { lbs in
                            Text("\(lbs) lbs").tag(lbs)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }

                // Height
                Button {
                    withAnimation { showHeightPicker.toggle(); showWeightPicker = false; showAgePicker = false }
                } label: {
                    HStack {
                        Text("Height")
                            .foregroundStyle(Color(.label))
                        Spacer()
                        let ft = heightInches / 12
                        let inch = heightInches % 12
                        Text("\(ft)'\(inch)\"")
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                    }
                }
                if showHeightPicker {
                    Picker("Height", selection: $heightInches) {
                        ForEach(48...96, id: \.self) { inches in
                            let ft = inches / 12
                            let inch = inches % 12
                            Text("\(ft)'\(inch)\"").tag(inches)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }

                // Age
                Button {
                    withAnimation { showAgePicker.toggle(); showWeightPicker = false; showHeightPicker = false }
                } label: {
                    HStack {
                        Text("Age")
                            .foregroundStyle(Color(.label))
                        Spacer()
                        Text("\(age) yrs")
                            .foregroundStyle(DesignTokens.Colors.brandAccent)
                    }
                }
                if showAgePicker {
                    Picker("Age", selection: $age) {
                        ForEach(13...100, id: \.self) { yr in
                            Text("\(yr) yrs").tag(yr)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                }
            }

        }
        .scrollDismissesKeyboard(.interactively)
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
            if snapshot.weight > 0 { weightLbs = Int(snapshot.weight) }
            if snapshot.height > 0 { heightInches = Int(snapshot.height) }
            if snapshot.age > 0 { age = snapshot.age }
            gender = snapshot.gender ?? "Not specified"
        }
        if let photoData = try? await repo.fetchProfilePhoto(),
           let image = UIImage(data: photoData) {
            profileImage = image
        }
        isLoading = false
    }

    private func saveProfile() async {
        let weightKg = Double(weightLbs) / 2.20462
        let heightCm = Double(heightInches) * 2.54

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
