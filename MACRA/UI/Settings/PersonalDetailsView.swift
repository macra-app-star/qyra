import SwiftUI
import SwiftData

struct PersonalDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var weight: String = "--"
    @State private var height: String = "--"
    @State private var birthDateString: String = "--"
    @State private var gender: String = "Not specified"
    @State private var stepsTarget: String = "--"
    @State private var goalWeight: String = "--"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // GOAL section
                sectionBlock(header: "GOAL") {
                    HStack {
                        Text("Goal Weight")
                            .font(DesignTokens.Typography.bodyFont(16))
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Spacer()

                        NavigationLink {
                            GoalEditorView()
                        } label: {
                            Text("Change Goal")
                                .font(DesignTokens.Typography.medium(14))
                                .foregroundStyle(DesignTokens.Colors.brandAccent)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }

                // BODY section
                sectionBlock(header: "BODY") {
                    VStack(spacing: 0) {
                        detailRow(title: "Current Weight", value: weight)
                        Divider().padding(.leading, DesignTokens.Spacing.md)
                        detailRow(title: "Height", value: height)
                        Divider().padding(.leading, DesignTokens.Spacing.md)
                        detailRow(title: "Date of Birth", value: birthDateString)
                        Divider().padding(.leading, DesignTokens.Spacing.md)
                        detailRow(title: "Gender", value: gender)
                    }
                }

                // ACTIVITY section
                sectionBlock(header: "ACTIVITY") {
                    detailRow(title: "Daily Step Goal", value: stepsTarget)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(DesignTokens.Colors.background)
        .navigationTitle("Personal Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadProfile()
        }
    }

    private func loadProfile() async {
        let repo = ProfileRepository(modelContainer: modelContext.container)
        guard let snapshot = try? await repo.fetchProfileSnapshot() else { return }

        if snapshot.weight > 0 {
            weight = "\(Int(snapshot.weight.rounded())) lbs"
        }
        if snapshot.height > 0 {
            height = "\(Int(snapshot.height.rounded())) in"
        }
        if let bd = snapshot.birthDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            birthDateString = formatter.string(from: bd)
        }
        gender = snapshot.gender ?? "Not specified"
        if let steps = snapshot.stepsTarget, steps > 0 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            stepsTarget = formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
        }
        if let gw = snapshot.goalWeightKg, gw > 0 {
            let gwLbs = Int((gw * 2.20462).rounded())
            goalWeight = "\(gwLbs) lbs"
        }
    }

    @ViewBuilder
    private func sectionBlock(header: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(header)
                .font(DesignTokens.Typography.headlineFont(13))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
                .padding(.leading, DesignTokens.Spacing.xs)

            content()
                .background(DesignTokens.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(DesignTokens.Typography.bodyFont(16))
                .foregroundStyle(DesignTokens.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(DesignTokens.Typography.bodyFont(16))
                .foregroundStyle(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
    }
}
