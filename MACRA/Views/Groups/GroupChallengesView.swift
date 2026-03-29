import SwiftUI

// MARK: - Challenge Models

struct Challenge: Identifiable, Codable {
    let id: UUID
    var title: String
    var metric: ChallengeMetric
    var startDate: Date
    var endDate: Date
    var status: ChallengeStatus
    var participants: [ChallengeParticipant]

    init(id: UUID = UUID(), title: String, metric: ChallengeMetric, startDate: Date, endDate: Date, status: ChallengeStatus = .active, participants: [ChallengeParticipant] = []) {
        self.id = id
        self.title = title
        self.metric = metric
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.participants = participants
    }
}

enum ChallengeMetric: String, Codable, CaseIterable, Identifiable {
    case calorieTarget, proteinTarget, mealConsistency, workoutConsistency, totalWorkouts, caloriesBurned, streakLength

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .calorieTarget: return "Calorie Target"
        case .proteinTarget: return "Protein Target"
        case .mealConsistency: return "Meal Consistency"
        case .workoutConsistency: return "Workout Consistency"
        case .totalWorkouts: return "Total Workouts"
        case .caloriesBurned: return "Calories Burned"
        case .streakLength: return "Streak Challenge"
        }
    }

    var icon: String {
        switch self {
        case .calorieTarget: return "flame.fill"
        case .proteinTarget: return "fork.knife"
        case .mealConsistency: return "calendar"
        case .workoutConsistency: return "figure.run"
        case .totalWorkouts: return "dumbbell.fill"
        case .caloriesBurned: return "bolt.fill"
        case .streakLength: return "flame"
        }
    }
}

enum ChallengeStatus: String, Codable {
    case draft, pendingInvites, active, completed, cancelled
}

struct ChallengeParticipant: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let displayName: String
    var currentScore: Double
    var rank: Int?

    init(id: UUID = UUID(), userId: UUID = UUID(), displayName: String, currentScore: Double = 0, rank: Int? = nil) {
        self.id = id
        self.userId = userId
        self.displayName = displayName
        self.currentScore = currentScore
        self.rank = rank
    }
}

// MARK: - Challenges View

struct GroupChallengesView: View {
    let group: GroupModel
    @State private var showCreateChallenge = false
    @State private var challenges: [Challenge] = []

    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.md) {
                if challenges.isEmpty {
                    // Empty state
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Spacer().frame(height: 40)

                        Text("No challenges yet")
                            .font(.headline)
                            .foregroundStyle(DesignTokens.Colors.textPrimary)

                        Text("Challenge your group members to hit their goals")
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button {
                            showCreateChallenge = true
                        } label: {
                            Label("Create Challenge", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentColor)
                        .padding(.horizontal, 40)
                    }
                } else {
                    // Active challenges
                    ForEach(challenges) { challenge in
                        challengeCard(challenge)
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)

                    Button {
                        showCreateChallenge = true
                    } label: {
                        Label("New Challenge", systemImage: "plus")
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.top, DesignTokens.Spacing.sm)
                }
            }
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .sheet(isPresented: $showCreateChallenge) {
            NavigationStack {
                CreateChallengeView(group: group) { challenge in
                    challenges.append(challenge)
                }
            }
        }
    }

    private func challengeCard(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: challenge.metric.icon)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Text(challenge.metric.displayName)
                        .font(.caption)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
                Spacer()
                statusBadge(challenge.status)
            }

            // Mini leaderboard
            ForEach(challenge.participants.sorted { ($0.rank ?? 99) < ($1.rank ?? 99) }) { p in
                HStack {
                    Text("#\(p.rank ?? 0)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(p.rank == 1 ? .orange : DesignTokens.Colors.textSecondary)
                        .frame(width: 30)
                    Text(p.displayName)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                    Spacer()
                    Text("\(Int(p.currentScore))")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(DesignTokens.Colors.textPrimary)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func statusBadge(_ status: ChallengeStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(status == .active ? .green : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                (status == .active ? Color.green : Color.secondary).opacity(0.15),
                in: Capsule()
            )
    }
}

// MARK: - Create Challenge View

struct CreateChallengeView: View {
    let group: GroupModel
    let onCreate: (Challenge) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var selectedMetric: ChallengeMetric = .calorieTarget
    @State private var durationDays = 7
    @State private var targetValue = ""
    @State private var selectedParticipants: Set<String> = []

    // Target value field visibility
    private var showsTargetField: Bool {
        switch selectedMetric {
        case .calorieTarget, .proteinTarget: return true
        default: return false
        }
    }

    private var targetLabel: String {
        switch selectedMetric {
        case .calorieTarget: return "Daily calorie target"
        case .proteinTarget: return "Daily protein target (g)"
        default: return "Target"
        }
    }

    private var targetUnit: String {
        selectedMetric == .calorieTarget ? "cal" : "g"
    }

    var body: some View {
        Form {
            Section("Challenge") {
                TextField("Challenge name", text: $title)

                Picker("Type", selection: $selectedMetric) {
                    ForEach(ChallengeMetric.allCases) { metric in
                        Label(metric.displayName, systemImage: metric.icon)
                            .tag(metric)
                    }
                }

                // Target value (conditional)
                if showsTargetField {
                    HStack {
                        Text(targetLabel)
                            .font(.subheadline)
                        Spacer()
                        TextField("0", text: $targetValue)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text(targetUnit)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Duration") {
                Picker("Duration", selection: $durationDays) {
                    Text("1 Day").tag(1)
                    Text("7 Days").tag(7)
                    Text("14 Days").tag(14)
                    Text("30 Days").tag(30)
                }
                .pickerStyle(.segmented)
            }

            // Participants
            Section("Participants") {
                if group.memberCount <= 1 {
                    HStack {
                        Image(systemName: "person.2.slash")
                            .foregroundStyle(.secondary)
                        Text("Invite members to your group first")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    // Placeholder participant rows (group members would come from backend)
                    Text("All group members will be invited")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    let challenge = Challenge(
                        title: title.isEmpty ? selectedMetric.displayName : title,
                        metric: selectedMetric,
                        startDate: .now,
                        endDate: Calendar.current.date(byAdding: .day, value: durationDays, to: .now) ?? .now,
                        status: .active,
                        participants: [
                            ChallengeParticipant(displayName: "You", currentScore: 0, rank: 1)
                        ]
                    )
                    onCreate(challenge)
                    dismiss()
                } label: {
                    Text("Start Challenge")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .disabled(title.isEmpty)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("New Challenge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}

#Preview {
    GroupChallengesView(group: GroupModel(name: "Test", isPrivate: false))
}
