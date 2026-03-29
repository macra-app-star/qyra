import SwiftUI
import SwiftData

struct FastingDetailView: View {
    @Bindable var session: FastingSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    VStack(spacing: 24) {
                        // Timer ring
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 12)
                            Circle()
                                .trim(from: 0, to: session.progress)
                                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 1), value: session.progress)
                            VStack(spacing: 4) {
                                Text(formatDuration(session.remaining))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                Text("remaining")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 200, height: 200)
                        .padding(.top, 24)

                        // Schedule info
                        HStack {
                            infoBlock("Schedule", value: session.schedule.rawValue)
                            Spacer()
                            infoBlock("Elapsed", value: formatDuration(session.elapsed))
                            Spacer()
                            infoBlock("Goal", value: "\(Int(session.targetDuration / 3600))h")
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Eating window
                        let eatingStart = session.startTime.addingTimeInterval(session.targetDuration)
                        VStack(spacing: 8) {
                            Text("Eating window opens")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(eatingStart, style: .time)
                                .font(.title3.weight(.semibold))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // End Fast button
                        if session.remaining > 0 {
                            Button {
                                session.endTime = Date()
                                try? modelContext.save()
                                DesignTokens.Haptics.success()
                                dismiss()
                            } label: {
                                Text("End Fast")
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.accentColor)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.green)
                                Text("Fast complete!")
                                    .font(.headline)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Fasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func infoBlock(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
