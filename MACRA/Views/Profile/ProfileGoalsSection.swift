import SwiftUI

struct ProfileGoalsSection: View {
    @Binding var healthKitAuthorized: Bool

    var body: some View {
        Section {
            // Apple Health row with connected/connect toggle
            HStack {
                Label("Apple Health", systemImage: "heart.fill")
                Spacer()
                if healthKitAuthorized {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.green)
                        Text("Connected")
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                    }
                } else {
                    Button("Connect") {
                        Task {
                            let result = await HealthKitService.shared.requestAuthorization()
                            healthKitAuthorized = result
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                }
            }

            NavigationLink {
                GoalEditorView()
            } label: {
                Label("Edit Nutrition Goals", systemImage: "target")
            }

            NavigationLink {
                WeightHistoryView()
            } label: {
                Label("Goals & current weight", systemImage: "chart.bar")
            }

            NavigationLink {
                TrackingRemindersView()
            } label: {
                Label("Tracking Reminders", systemImage: "bell")
            }

            NavigationLink {
                WeightHistoryView()
            } label: {
                Label("Weight History", systemImage: "clock")
            }

            NavigationLink {
                RingColorsExplainedView()
            } label: {
                Label("Ring Colors Explained", systemImage: "circle.dotted")
            }

            NavigationLink {
                CompoundsDashboardView()
            } label: {
                Label("Supplements & Compounds", systemImage: "pills.circle")
            }

        } header: {
            Text("Goals & Tracking")
                .font(DesignTokens.Typography.medium(13))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
                .textCase(nil)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            ProfileGoalsSection(healthKitAuthorized: .constant(false))
        }
        .listStyle(.insetGrouped)
    }
}
