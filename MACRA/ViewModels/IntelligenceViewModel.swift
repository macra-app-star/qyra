import SwiftUI
import SwiftData
import PhotosUI

@Observable @MainActor
final class IntelligenceViewModel {
    var messages: [CoachMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var selectedPhoto: PhotosPickerItem? = nil
    var attachedImage: UIImage? = nil

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let welcome = CoachMessage(
            role: .assistant,
            content: "I'm your Qyra AI specialist. I know your nutrition history, body metrics, and health data. Ask me anything — diet advice, supplement recommendations, routine optimization, or upload photos like blood test results for personalized analysis.",
            timestamp: .now
        )
        messages.append(welcome)
    }

    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = CoachMessage(role: .user, content: text, timestamp: .now)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        let context = await buildContext()

        do {
            let response = try await NutritionService.shared.getCoachInsight(
                context: "\(context)\n\nUser question: \(text)"
            )
            let assistantMessage = CoachMessage(role: .assistant, content: response, timestamp: .now)
            messages.append(assistantMessage)
        } catch {
            #if DEBUG
            print("[Qyra AI] Error: \(error)")
            #endif
            let displayMessage: String
            if let apiError = error as? APIError {
                switch apiError {
                case .unauthorized:
                    displayMessage = "API key issue. Please check your Gemini API configuration."
                case .rateLimited:
                    displayMessage = "I'm receiving too many requests right now. Please wait a moment and try again."
                case .networkError:
                    displayMessage = "No network connection. Please check your internet and try again."
                case .invalidResponse(let code):
                    displayMessage = "Server returned an error (code \(code)). Please try again."
                default:
                    displayMessage = "Something went wrong. Please try again."
                }
            } else {
                displayMessage = "Something went wrong. Please try again."
            }
            let errorMsg = CoachMessage(
                role: .assistant,
                content: displayMessage,
                timestamp: .now
            )
            messages.append(errorMsg)
        }

        isLoading = false
    }

    func sendSuggestion(_ text: String) async {
        inputText = text
        await send()
    }

    func processSelectedPhoto() async {
        guard let selectedPhoto else { return }
        guard let data = try? await selectedPhoto.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        attachedImage = image
        self.selectedPhoto = nil

        let userMessage = CoachMessage(role: .user, content: "📎 [Uploaded an image for analysis]", timestamp: .now)
        messages.append(userMessage)
        isLoading = true

        let context = await buildContext()

        do {
            let response = try await NutritionService.shared.getCoachInsight(
                context: "\(context)\n\nThe user uploaded an image (e.g., blood test results, food photo, supplement label). Since you cannot see the image directly, ask them to describe what's in it or type out the key values so you can provide personalized analysis."
            )
            let assistantMessage = CoachMessage(role: .assistant, content: response, timestamp: .now)
            messages.append(assistantMessage)
        } catch {
            #if DEBUG
            print("[Qyra AI] Photo error: \(error)")
            #endif
            let errorMsg = CoachMessage(
                role: .assistant,
                content: "I couldn't process that image right now. Please try again.",
                timestamp: .now
            )
            messages.append(errorMsg)
        }

        attachedImage = nil
        isLoading = false
    }

    private func buildContext() async -> String {
        let context = ModelContext(modelContainer)
        var parts: [String] = []

        // System prompt
        parts.append("""
        You are Qyra AI, a premium personal AI nutrition and health specialist. \
        You have deep knowledge of the user through their profile, tracking history, and health data. \
        Provide thoughtful, evidence-based advice on diet, supplements, routines, and lifestyle. \
        Be conversational, warm, and specific. Use their data to personalize every response. \
        Never give medical diagnoses but do provide actionable health optimization advice. \
        Keep responses concise but thorough (3-5 sentences typically).
        """)

        // Profile data
        let profileRepo = ProfileRepository(modelContainer: modelContainer)
        if let snapshot = try? await profileRepo.fetchProfileSnapshot() {
            var profileParts: [String] = []
            if let name = snapshot.displayName { profileParts.append("Name: \(name)") }
            if snapshot.weight > 0 { profileParts.append("Weight: \(Int(snapshot.weight.rounded())) lbs") }
            if snapshot.height > 0 {
                let totalIn = Int(snapshot.height.rounded())
                profileParts.append("Height: \(totalIn / 12)'\(totalIn % 12)\"")
            }
            if snapshot.age > 0 { profileParts.append("Age: \(snapshot.age)") }
            if let gender = snapshot.gender { profileParts.append("Gender: \(gender)") }
            if let gw = snapshot.goalWeightKg, gw > 0 {
                profileParts.append("Goal weight: \(Int((gw * 2.20462).rounded())) lbs")
            }
            if let steps = snapshot.stepsTarget, steps > 0 {
                profileParts.append("Daily step goal: \(steps)")
            }
            if !profileParts.isEmpty {
                parts.append("User profile: \(profileParts.joined(separator: ", "))")
            }
        }

        // Today's meals
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = #Predicate<MealLog> { meal in
            meal.date >= startOfDay
        }
        let descriptor = FetchDescriptor<MealLog>(predicate: predicate)
        let todayMeals = (try? context.fetch(descriptor)) ?? []

        if !todayMeals.isEmpty {
            let totalCal = todayMeals.reduce(0.0) { $0 + $1.totalCalories }
            let totalP = todayMeals.reduce(0.0) { $0 + $1.totalProtein }
            let totalC = todayMeals.reduce(0.0) { $0 + $1.totalCarbs }
            let totalF = todayMeals.reduce(0.0) { $0 + $1.totalFat }
            parts.append("Today's intake: \(Int(totalCal)) cal, \(Int(totalP))g protein, \(Int(totalC))g carbs, \(Int(totalF))g fat from \(todayMeals.count) meals")
        } else {
            parts.append("No meals logged today yet.")
        }

        // Macro goals
        let goalDescriptor = FetchDescriptor<MacroGoal>()
        let goals = (try? context.fetch(goalDescriptor)) ?? []
        if let goal = goals.first {
            parts.append("Daily goals: \(goal.dailyCalorieGoal) cal, \(goal.dailyProteinGoal)g protein, \(goal.dailyCarbGoal)g carbs, \(goal.dailyFatGoal)g fat")
        }

        // Weekly context
        let weekStart = calendar.date(byAdding: .day, value: -7, to: startOfDay) ?? startOfDay
        let weekPredicate = #Predicate<MealLog> { meal in
            meal.date >= weekStart
        }
        let weekDescriptor = FetchDescriptor<MealLog>(predicate: weekPredicate)
        let weekMeals = (try? context.fetch(weekDescriptor)) ?? []
        if weekMeals.count > todayMeals.count {
            let uniqueDays = Set(weekMeals.map { calendar.startOfDay(for: $0.date) })
            let weekCal = weekMeals.reduce(0.0) { $0 + $1.totalCalories }
            let avgCal = uniqueDays.count > 0 ? Int(weekCal) / uniqueDays.count : 0
            parts.append("This week: \(uniqueDays.count) days logged, avg \(avgCal) cal/day")
        }

        // HealthKit data
        let steps = await HealthKitService.shared.todaySteps()
        let activeCalories = await HealthKitService.shared.todayActiveCalories()
        if steps > 0 || activeCalories > 0 {
            parts.append("Today's activity: \(steps) steps, \(activeCalories) active calories burned")
        }

        // Conversation history (last 6 messages for context)
        let recentMessages = messages.suffix(6)
        if recentMessages.count > 1 {
            let history = recentMessages.map { msg in
                let role = msg.role == .user ? "User" : "Assistant"
                return "\(role): \(msg.content)"
            }.joined(separator: "\n")
            parts.append("Recent conversation:\n\(history)")
        }

        return parts.joined(separator: "\n")
    }
}
