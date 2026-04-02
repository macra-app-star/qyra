import SwiftUI
import SwiftData
import UserNotifications

// MARK: - Dose Formatting (inlined — file not in Xcode target)
extension Double {
    var doseFormatted: String {
        if self >= 1000 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        }
        if self.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", self)
        }
        return String(self)
    }
}

struct CompoundsDashboardView: View {
    @Query(sort: \CompoundRegimen.createdAt, order: .reverse) private var regimens: [CompoundRegimen]
    @Query(sort: \CompoundEntry.loggedAt, order: .reverse) private var entries: [CompoundEntry]
    @State private var showAddRegimen = false
    @State private var showLogDose = false
    @State private var selectedRegimen: CompoundRegimen?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if regimens.isEmpty {
                    emptyState
                } else {
                    ForEach(regimens.filter(\.isActive)) { regimen in
                        regimenCard(regimen)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    selectedRegimen = regimen
                                    showLogDose = true
                                } label: {
                                    Label("Log", systemImage: "checkmark.circle.fill")
                                }
                                .tint(.accentColor)
                            }
                            .contextMenu {
                                Button {
                                    selectedRegimen = regimen
                                    showLogDose = true
                                } label: {
                                    Label("Log Dose", systemImage: "plus.circle")
                                }
                            }
                    }

                    if !entries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(.headline)
                            ForEach(Array(entries.prefix(10))) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.name)
                                            .font(.subheadline.weight(.medium))
                                        Text("\(entry.dose.doseFormatted) \(entry.unit) • \(entry.administrationMethod)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.loggedAt, style: .relative)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Compounds")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddRegimen = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddRegimen) {
            NavigationStack { AddRegimenView() }
        }
        .sheet(isPresented: $showLogDose) {
            NavigationStack { LogDoseView() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(spacing: 8) {
                Text("No compounds tracked")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Text("Add supplements, medications, or compounds to track your regimen.")
                    .font(.system(.subheadline))
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                showAddRegimen = true
            } label: {
                Label("Add Compound", systemImage: "plus")
                    .font(.system(.headline, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(.vertical, 40)
    }

    private func regimenCard(_ regimen: CompoundRegimen) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(regimen.compoundName)
                    .font(.headline)
                Spacer()
                Text(regimen.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Capsule())
            }
            HStack(spacing: 12) {
                Label("\(regimen.standardDose.doseFormatted) \(regimen.unit)", systemImage: "eyedropper")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(regimen.frequency, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Add Regimen

struct AddRegimenView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var category = "Supplement"
    @State private var method = "Oral"
    @State private var dose = ""
    @State private var unit = "mg"
    @State private var frequency = "Daily"
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()

    private func scheduleReminder(for regimen: CompoundRegimen) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }

        let content = UNMutableNotificationContent()
        content.title = "Time to take \(regimen.compoundName)"
        content.body = "\(regimen.standardDose) \(regimen.unit) — \(regimen.method)"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: regimen.reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "compound-\(regimen.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private let categories = ["Supplement", "Medication", "Peptide", "Hormone", "Vitamin", "Custom"]
    private let methods = ["Oral", "Injection", "Sublingual", "Topical", "Powder", "Liquid", "Patch"]
    private let frequencies = ["Daily", "Twice Daily", "Every Other Day", "Weekly", "Biweekly", "Monthly", "As Needed"]
    private let units = ["mg", "mcg", "IU", "ml", "g", "capsule", "tablet"]

    var body: some View {
        Form {
            Section("Compound") {
                TextField("Name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0) }
                }
                Picker("Method", selection: $method) {
                    ForEach(methods, id: \.self) { Text($0) }
                }
            }
            Section("Dosage") {
                HStack {
                    TextField("Dose", text: $dose)
                        .keyboardType(.decimalPad)
                    Picker("", selection: $unit) {
                        ForEach(units, id: \.self) { Text($0) }
                    }
                    .labelsHidden()
                }
                Picker("Frequency", selection: $frequency) {
                    ForEach(frequencies, id: \.self) { Text($0) }
                }
            }

            Section("Reminder") {
                Toggle("Remind me", isOn: $reminderEnabled)
                    .tint(.accentColor)
                if reminderEnabled {
                    DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                }
            }
        }
        .navigationTitle("Add Compound")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let regimen = CompoundRegimen(
                        name: name, category: category, method: method,
                        dose: Double(dose) ?? 0, unit: unit, frequency: frequency
                    )
                    regimen.reminderEnabled = reminderEnabled
                    regimen.reminderTime = reminderTime

                    if reminderEnabled {
                        scheduleReminder(for: regimen)
                    }

                    context.insert(regimen)
                    dismiss()
                }
                .disabled(name.isEmpty || dose.isEmpty)
            }
        }
    }
}

// MARK: - Log Dose

struct LogDoseView: View {
    @Query(filter: #Predicate<CompoundRegimen> { $0.isActive }) private var regimens: [CompoundRegimen]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var selectedIndex: Int = 0
    @State private var dose = ""
    @State private var notes = ""
    @State private var site = ""
    @State private var painLevel: Double = 0

    var body: some View {
        Form {
            if regimens.isEmpty {
                Text("Add a compound first")
                    .foregroundStyle(.secondary)
            } else {
                Section("What") {
                    Picker("Compound", selection: $selectedIndex) {
                        ForEach(Array(regimens.enumerated()), id: \.offset) { i, r in
                            Text(r.compoundName).tag(i)
                        }
                    }
                    HStack {
                        Text("Dose")
                        Spacer()
                        TextField("Amount", text: $dose)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        if regimens.indices.contains(selectedIndex) {
                            Text(regimens[selectedIndex].unit)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if regimens.indices.contains(selectedIndex) && regimens[selectedIndex].method == "Injection" {
                    Section("Injection Details") {
                        TextField("Site (optional)", text: $site)
                        HStack {
                            Text("Pain")
                            Slider(value: $painLevel, in: 0...10, step: 1)
                            Text("\(Int(painLevel))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
        }
        .navigationTitle("Log Dose")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Log") {
                    guard regimens.indices.contains(selectedIndex) else { return }
                    let r = regimens[selectedIndex]
                    let entry = CompoundEntry(
                        name: r.compoundName, category: r.category, method: r.method,
                        dose: Double(dose) ?? r.standardDose, unit: r.unit
                    )
                    entry.notes = notes.isEmpty ? nil : notes
                    entry.site = site.isEmpty ? nil : site
                    entry.painLevel = Int(painLevel)
                    context.insert(entry)
                    DesignTokens.Haptics.success()
                    dismiss()
                }
                .disabled(regimens.isEmpty)
            }
        }
        .onAppear {
            if regimens.indices.contains(selectedIndex) {
                dose = "\(regimens[selectedIndex].standardDose)"
            }
        }
    }
}

#Preview {
    NavigationStack {
        CompoundsDashboardView()
    }
}
