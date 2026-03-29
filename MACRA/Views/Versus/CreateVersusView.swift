import SwiftUI
import SwiftData

struct CreateVersusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var selectedMetric: VersusMetric = .totalCaloriesBurned
    @State private var selectedDuration: VersusDuration = .sevenDays
    @State private var opponentUsername = ""
    @State private var stakes = ""

    var body: some View {
        NavigationStack {
            Form {
                // Challenge Setup
                Section("Challenge") {
                    TextField("Challenge name", text: $name)

                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(VersusMetric.allCases) { metric in
                            Label(metric.rawValue, systemImage: metric.icon).tag(metric)
                        }
                    }

                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(VersusDuration.allCases) { d in
                            Text(d.rawValue).tag(d)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Opponent
                Section {
                    Button {
                        // Share invite link
                    } label: {
                        Label("Share Invite Link", systemImage: "link")
                    }

                    HStack {
                        Text("@")
                            .foregroundStyle(.secondary)
                        TextField("opponent username", text: $opponentUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                } header: {
                    Text("Opponent")
                } footer: {
                    Text("Enter your opponent's Qyra username or share an invite link")
                }

                // Stakes
                Section {
                    TextField("Loser buys coffee ☕️", text: $stakes)
                } header: {
                    Text("Stakes (optional)")
                } footer: {
                    Text("A fun wager between friends — no real money")
                }

                // Start
                Section {
                    Button {
                        createVersus()
                    } label: {
                        HStack {
                            Image(systemName: "bolt.fill")
                            Text("Start VERSUS")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(name.isEmpty)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New VERSUS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createVersus() {
        let challenge = VersusChallenge(
            name: name,
            metric: selectedMetric,
            duration: selectedDuration,
            stakes: stakes,
            opponent: opponentUsername
        )
        modelContext.insert(challenge)
        DesignTokens.Haptics.success()
        dismiss()
    }
}

#Preview {
    CreateVersusView()
}
