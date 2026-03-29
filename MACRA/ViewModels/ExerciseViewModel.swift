import SwiftUI
import SwiftData

@Observable @MainActor
final class ExerciseViewModel {
    var selectedType: ExerciseType = .run
    var intensity: Int = 3 // 1-5
    var durationMinutes: Int = 30
    var caloriesBurned: Double = 0
    var exerciseDescription: String = ""
    var isEditing: Bool = false
    var isEstimating: Bool = false
    var didSave: Bool = false
    var errorMessage: String?

    private var modelContainer: ModelContainer?
    private let nutritionService = NutritionService.shared

    init() {}

    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func calculateCalories(weightKg: Double = 70) {
        let levels = selectedType.intensityLevels
        guard intensity >= 1, intensity <= levels.count else { return }
        let met = levels[intensity - 1].metValue
        let hours = Double(durationMinutes) / 60.0
        caloriesBurned = met * weightKg * hours
    }

    // MARK: - MET Lookup Table (20 activities)

    private static let metTable: [(keywords: [String], met: Double, name: String)] = [
        (["walk", "walking"], 3.5, "Walking"),
        (["jog", "jogging"], 7.0, "Jogging"),
        (["run", "running"], 9.8, "Running"),
        (["sprint", "sprinting"], 14.0, "Sprinting"),
        (["cycling", "biking", "bike", "cycle"], 7.5, "Cycling"),
        (["swim", "swimming"], 8.0, "Swimming"),
        (["basketball"], 6.5, "Basketball"),
        (["soccer", "football"], 7.0, "Soccer"),
        (["tennis"], 7.3, "Tennis"),
        (["yoga"], 3.0, "Yoga"),
        (["pilates"], 3.5, "Pilates"),
        (["hiking", "hike"], 6.0, "Hiking"),
        (["dance", "dancing"], 5.5, "Dancing"),
        (["jump rope", "jumping rope", "skipping"], 12.3, "Jump Rope"),
        (["rowing", "row"], 7.0, "Rowing"),
        (["elliptical"], 5.0, "Elliptical"),
        (["stair", "stairs", "stairmaster"], 9.0, "Stair Climbing"),
        (["weight", "weights", "lifting", "strength", "resistance"], 5.0, "Weight Training"),
        (["boxing", "kickboxing"], 7.8, "Boxing"),
        (["stretching", "stretch"], 2.5, "Stretching"),
    ]

    /// Parse duration from text using regex (supports "45 minutes", "1 hour", "1.5 hours", "30 min", etc.)
    private func parseDuration(from text: String) -> Int? {
        let lower = text.lowercased()

        // Match hours: "1 hour", "1.5 hours", "2 hr", "2hrs"
        if let hourMatch = lower.range(of: #"(\d+\.?\d*)\s*(?:hours?|hrs?)"#, options: .regularExpression) {
            let numStr = lower[hourMatch]
                .replacingOccurrences(of: #"\s*(?:hours?|hrs?)"#, with: "", options: .regularExpression)
            if let hours = Double(numStr) {
                return Int(hours * 60)
            }
        }

        // Match minutes: "45 minutes", "30 min", "20min", "15 mins"
        if let minMatch = lower.range(of: #"(\d+)\s*(?:minutes?|mins?)"#, options: .regularExpression) {
            let numStr = lower[minMatch]
                .replacingOccurrences(of: #"\s*(?:minutes?|mins?)"#, with: "", options: .regularExpression)
            if let mins = Int(numStr) {
                return mins
            }
        }

        // Match standalone number (assume minutes if activity is present)
        if let numMatch = lower.range(of: #"\b(\d+)\b"#, options: .regularExpression) {
            if let mins = Int(lower[numMatch]) {
                return mins
            }
        }

        return nil
    }

    /// Match activity keywords from the text against the MET lookup table
    private func matchActivity(from text: String) -> (met: Double, name: String)? {
        let lower = text.lowercased()
        for entry in Self.metTable {
            for keyword in entry.keywords {
                if lower.contains(keyword) {
                    return (entry.met, entry.name)
                }
            }
        }
        return nil
    }

    /// Local parsing: extract duration and activity, calculate calories using MET formula
    struct LocalParseResult {
        let activityName: String
        let durationMinutes: Int
        let metValue: Double
        let caloriesBurned: Double
    }

    private func parseLocally(_ description: String, weightKg: Double) -> LocalParseResult? {
        let duration = parseDuration(from: description)
        let activity = matchActivity(from: description)

        // Need at least an activity match to do local parsing
        guard let activity = activity else { return nil }

        let mins = duration ?? durationMinutes // fallback to current stepper value
        let hours = Double(mins) / 60.0
        let calories = activity.met * weightKg * hours

        return LocalParseResult(
            activityName: activity.name,
            durationMinutes: mins,
            metValue: activity.met,
            caloriesBurned: calories
        )
    }

    func estimateFromDescription(weightKg: Double = 70) async {
        let desc = exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !desc.isEmpty else {
            caloriesBurned = 200
            return
        }

        isEstimating = true

        // Try local parsing first (fast, no network needed)
        if let local = parseLocally(desc, weightKg: weightKg) {
            caloriesBurned = local.caloriesBurned
            durationMinutes = local.durationMinutes
            isEstimating = false
            return
        }

        // Fallback to AI if local parsing cannot identify the activity
        do {
            let estimate = try await nutritionService.estimateExercise(
                description: desc,
                weightKg: weightKg,
                durationMinutes: durationMinutes
            )
            caloriesBurned = estimate.caloriesBurned
            durationMinutes = estimate.durationMinutes
        } catch {
            // Final fallback: rough estimate based on duration
            let hours = Double(durationMinutes) / 60.0
            caloriesBurned = 5.0 * weightKg * hours // ~5 MET average
        }

        isEstimating = false
    }

    func logExercise() {
        guard let container = modelContainer else { return }

        let entry = ExerciseEntry(
            exerciseType: selectedType.rawValue,
            name: selectedType == .describe ? exerciseDescription : selectedType.displayName,
            durationMinutes: durationMinutes,
            caloriesBurned: caloriesBurned,
            intensity: Double(intensity) / 5.0,
            source: selectedType == .describe ? .ai : .manual
        )

        let exerciseName = selectedType == .describe ? exerciseDescription : selectedType.displayName
        let duration = durationMinutes
        let calories = caloriesBurned

        Task {
            let context = ModelContext(container)
            context.insert(entry)
            try? context.save()
            didSave = true
            NotificationCenter.default.post(name: .exerciseLogged, object: nil)

            // Write workout to Apple Health
            let activityType = HealthKitService.activityType(for: exerciseName)
            await HealthKitService.shared.saveWorkout(
                name: exerciseName,
                activityType: activityType,
                durationMinutes: duration,
                caloriesBurned: calories,
                date: Date()
            )
        }
    }
}
