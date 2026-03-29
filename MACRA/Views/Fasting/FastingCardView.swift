import SwiftUI
import SwiftData

struct FastingCardView: View {
    @Query(
        filter: #Predicate<FastingSession> { $0.endTime == nil },
        sort: \FastingSession.startTime,
        order: .reverse
    ) private var activeSessions: [FastingSession]

    @State private var showSetup = false
    @State private var showDetail = false

    private var activeSession: FastingSession? {
        activeSessions.first(where: { $0.isActive })
    }

    var body: some View {
        Group {
            if let session = activeSession {
                Button { showDetail = true } label: {
                    activeFastingCard(session)
                }
                .buttonStyle(.plain)
            } else {
                inactiveFastingCard
            }
        }
        .sheet(isPresented: $showSetup) {
            NavigationStack {
                FastingSetupView()
            }
        }
        .sheet(isPresented: $showDetail) {
            if let session = activeSession {
                FastingDetailView(session: session)
            }
        }
    }

    // MARK: - Inactive Card

    private var inactiveFastingCard: some View {
        Button { showSetup = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "timer")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Fasting")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text("Start an intermittent fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active Card

    private func activeFastingCard(_ session: FastingSession) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Image(systemName: "timer")
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                    Text("Fasting")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(session.schedule.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * session.progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text(formatDuration(session.elapsed) + " elapsed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDuration(session.remaining) + " remaining")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.accentColor)
                }

                if session.remaining <= 0 {
                    Text("Fast complete!")
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Setup View

struct FastingSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var selectedSchedule: FastingSchedule = .sixteenEight
    @State private var customHours = 16

    var body: some View {
        Form {
            Section("Schedule") {
                ForEach(FastingSchedule.allCases) { schedule in
                    Button {
                        selectedSchedule = schedule
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(schedule.rawValue)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                                if let sub = schedule.subtitle {
                                    Text(sub)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if selectedSchedule == schedule {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                }

                if selectedSchedule == .custom {
                    Stepper("Fast for \(customHours) hours", value: $customHours, in: 1...23)
                }
            }

            Section {
                let hours = selectedSchedule == .custom ? customHours : selectedSchedule.fastingHours
                let eating = 24 - hours
                let endTime = Calendar.current.date(byAdding: .hour, value: hours, to: Date()) ?? Date()

                HStack {
                    Text("Eating window")
                    Spacer()
                    Text("\(eating) hours")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Fast ends")
                    Spacer()
                    Text(endTime, style: .time)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Summary")
            }

            Section {
                Button {
                    startFast()
                } label: {
                    Text("Start Fast")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Start Fast")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func startFast() {
        let session = FastingSession(schedule: selectedSchedule)
        if selectedSchedule == .custom {
            session.targetDuration = TimeInterval(customHours) * 3600
        }
        modelContext.insert(session)
        DesignTokens.Haptics.success()
        dismiss()
    }
}

#Preview {
    FastingCardView()
}
