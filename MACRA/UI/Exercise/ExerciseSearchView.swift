import SwiftUI
import SwiftData

// INTEGRATED FROM: ExerciseDB
// Searchable exercise browser with body part filtering.

struct ExerciseSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedBodyPart: BodyPartCategory?
    @State private var selectedEquipment: String?
    @State private var exercises: [Exercise] = []
    @State private var isLoading = false
    @State private var selectedExercise: Exercise?
    @State private var availableEquipment: [String] = []

    let onSelect: ((Exercise) -> Void)?
    let onAddToWorkout: ((Exercise) -> Void)?

    init(onSelect: ((Exercise) -> Void)? = nil, onAddToWorkout: ((Exercise) -> Void)? = nil) {
        self.onSelect = onSelect
        self.onAddToWorkout = onAddToWorkout
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Body part filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        filterChip("All", isSelected: selectedBodyPart == nil) {
                            selectedBodyPart = nil
                            performSearch()
                        }

                        ForEach(BodyPartCategory.allCases) { part in
                            filterChip(part.displayName, isSelected: selectedBodyPart == part) {
                                selectedBodyPart = part
                                performSearch()
                            }
                        }
                    }
                    .padding(.horizontal, DesignTokens.Layout.screenMargin)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                }

                // Equipment filter chips
                if !availableEquipment.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            filterChip("Any", isSelected: selectedEquipment == nil) {
                                selectedEquipment = nil
                                performSearch()
                            }

                            ForEach(availableEquipment, id: \.self) { eq in
                                filterChip(eq.capitalized, isSelected: selectedEquipment == eq) {
                                    selectedEquipment = eq
                                    performSearch()
                                }
                            }
                        }
                        .padding(.horizontal, DesignTokens.Layout.screenMargin)
                        .padding(.bottom, DesignTokens.Spacing.sm)
                    }
                }

                // Results
                if exercises.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No exercises found",
                        systemImage: "dumbbell",
                        description: Text(searchText.isEmpty ? "Browse by body part or search above" : "Try a different search term")
                    )
                } else {
                    List(exercises) { exercise in
                        Button {
                            selectedExercise = exercise
                        } label: {
                            exerciseRow(exercise)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises...")
            .onChange(of: searchText) { _, _ in performSearch() }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(
                    exercise: exercise,
                    onLog: onSelect,
                    onAddToWorkout: onAddToWorkout != nil ? { ex in
                        onAddToWorkout?(ex)
                    } : nil
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
            performSearch()
            loadEquipmentOptions()
        }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: DesignTokens.Layout.itemGap) {
            // Icon
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.neutral90)
                    .frame(width: 44, height: 44)
                Image(systemName: iconForBodyPart(exercise.bodyPart))
                    .font(.system(size: 18))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name.capitalized)
                    .font(QyraFont.semibold(15))
                    .foregroundStyle(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: DesignTokens.Spacing.sm) {
                    Text(exercise.targetMuscle.capitalized)
                        .font(QyraFont.regular(13))
                        .foregroundStyle(DesignTokens.Colors.textSecondary)

                    if !exercise.equipment.isEmpty {
                        Text("·")
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                        Text(exercise.equipment.capitalized)
                            .font(QyraFont.regular(13))
                            .foregroundStyle(DesignTokens.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            if exercise.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DesignTokens.Colors.error)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DesignTokens.Colors.textTertiary)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }

    // MARK: - Filter Chip

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(QyraFont.medium(13))
                .foregroundStyle(isSelected ? .white : DesignTokens.Colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : DesignTokens.Colors.neutral90)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Search

    private func loadEquipmentOptions() {
        // Query directly on main context to avoid cross-context crash
        let descriptor = FetchDescriptor<Exercise>()
        guard let allExercises = try? modelContext.fetch(descriptor) else { return }
        let equipmentSet = Set(allExercises.map(\.equipment))
        availableEquipment = equipmentSet.sorted()
    }

    private func performSearch() {
        // Query directly on main context to avoid SwiftData threading crash
        if let equipment = selectedEquipment {
            let descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.equipment == equipment },
                sortBy: [SortDescriptor(\.name)]
            )
            exercises = (try? modelContext.fetch(descriptor)) ?? []
        } else if let bodyPart = selectedBodyPart {
            let bp = bodyPart.rawValue
            let descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.bodyPart == bp },
                sortBy: [SortDescriptor(\.name)]
            )
            exercises = (try? modelContext.fetch(descriptor)) ?? []
        } else if searchText.count >= 2 {
            let query = searchText.lowercased()
            let descriptor = FetchDescriptor<Exercise>(
                predicate: #Predicate { $0.searchName.contains(query) },
                sortBy: [SortDescriptor(\.name)]
            )
            var limited = descriptor
            limited.fetchLimit = 50
            exercises = (try? modelContext.fetch(limited)) ?? []
        } else {
            var descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
            descriptor.fetchLimit = 50
            exercises = (try? modelContext.fetch(descriptor)) ?? []
        }
    }

    private func iconForBodyPart(_ bodyPart: String) -> String {
        BodyPartCategory(rawValue: bodyPart)?.icon ?? "figure.strengthtraining.traditional"
    }
}

#Preview {
    ExerciseSearchView()
}
