import SwiftUI
import SwiftData

struct WeightHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.timestamp, order: .reverse) private var entries: [WeightEntry]

    @State private var showLogSheet = false
    @State private var weightInput = ""

    var body: some View {
        VStack(spacing: 0) {
            // Log Weight button
            Button {
                weightInput = ""
                showLogSheet = true
            } label: {
                Text("Log Weight")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.sm)

            if entries.isEmpty {
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Spacer()
                    EmptyDataView(
                        title: "No Weight Entries",
                        subtitle: "Log your first weigh-in to start tracking progress."
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(entries) { entry in
                        HStack {
                            Text(entry.timestamp, format: .dateTime.month(.abbreviated).day().year())
                                .font(.body)
                                .foregroundStyle(Color(.label))
                            Spacer()
                            Text("\(entry.weightLbs, specifier: "%.1f") lbs")
                                .font(.body)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                    }
                    .onDelete(perform: deleteEntries)
                }
                .listStyle(.insetGrouped)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weight History")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLogSheet) {
            LogWeightSheet(weightInput: $weightInput) { value in
                saveWeight(value)
                showLogSheet = false
            }
            .presentationDetents([.height(220)])
        }
    }

    private func saveWeight(_ lbs: Double) {
        let entry = WeightEntry(weightLbs: lbs, timestamp: Date())
        modelContext.insert(entry)
        try? modelContext.save()
        NotificationCenter.default.post(name: .weightLogged, object: nil)

        // Write to HealthKit
        Task { await HealthKitService.shared.saveWeight(lbs: lbs, date: Date()) }
    }

    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
        NotificationCenter.default.post(name: .weightLogged, object: nil)
    }
}

// MARK: - Log Weight Sheet

private struct LogWeightSheet: View {
    @Binding var weightInput: String
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.lg) {
                TextField("Weight in lbs", text: $weightInput)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, DesignTokens.Spacing.md)

                if let value = Double(weightInput), (value < 50 || value > 1000) {
                    Text("Enter a weight between 50 and 1000 lbs.")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Button {
                    guard let value = Double(weightInput), value >= 50, value <= 1000 else { return }
                    onSave(value)
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .disabled({
                    guard let v = Double(weightInput) else { return true }
                    return v < 50 || v > 1000
                }())

                Spacer()
            }
            .padding(.top, DesignTokens.Spacing.lg)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
