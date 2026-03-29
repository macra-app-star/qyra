import SwiftUI
import SwiftData

struct CoachMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date

    enum Role {
        case user, assistant, system
    }
}

@Observable
final class AICoachViewModel {
    var messages: [CoachMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false

    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let welcome = CoachMessage(
            role: .assistant,
            content: "Hey! I'm your Qyra AI coach. Ask me anything about your nutrition, macros, meal ideas, or fitness goals. How can I help today?",
            timestamp: .now
        )
        messages.append(welcome)
    }

    @MainActor
    func send() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = CoachMessage(role: .user, content: text, timestamp: .now)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        // Build context from today's data
        let context = await buildContext()

        // Build message history for the Edge Function
        let chatHistory: [[String: String]] = messages.compactMap { msg in
            switch msg.role {
            case .user: return ["role": "user", "content": msg.content]
            case .assistant: return ["role": "assistant", "content": msg.content]
            case .system: return nil
            }
        }

        do {
            let response = try await SupabaseAPIService.shared.chatWithCoach(
                messages: chatHistory,
                context: context
            )
            let assistantMessage = CoachMessage(role: .assistant, content: response, timestamp: .now)
            messages.append(assistantMessage)
        } catch {
            let errorMessage = CoachMessage(
                role: .assistant,
                content: "Sorry, I couldn't process that right now. Please try again.",
                timestamp: .now
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    @MainActor
    private func buildContext() async -> String {
        let context = ModelContext(modelContainer)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        // Fetch today's meals
        let predicate = #Predicate<MealLog> { meal in
            meal.date >= startOfDay
        }
        let descriptor = FetchDescriptor<MealLog>(predicate: predicate)
        let todayMeals = (try? context.fetch(descriptor)) ?? []

        // Fetch goals
        let goalDescriptor = FetchDescriptor<MacroGoal>()
        let goals = (try? context.fetch(goalDescriptor)) ?? []
        let goal = goals.first

        var contextParts: [String] = []
        contextParts.append("You are Qyra AI, a friendly and knowledgeable nutrition AI assistant.")
        contextParts.append("Be concise, supportive, and actionable. Use a casual, encouraging tone.")
        contextParts.append("Focus on evidence-based nutrition advice.")

        if let goal = goal {
            contextParts.append("User's daily goals: \(goal.dailyCalorieGoal) cal, \(goal.dailyProteinGoal)g protein, \(goal.dailyCarbGoal)g carbs, \(goal.dailyFatGoal)g fat")
        }

        if !todayMeals.isEmpty {
            let totalCal = todayMeals.reduce(0.0) { $0 + $1.totalCalories }
            let totalP = todayMeals.reduce(0.0) { $0 + $1.totalProtein }
            let totalC = todayMeals.reduce(0.0) { $0 + $1.totalCarbs }
            let totalF = todayMeals.reduce(0.0) { $0 + $1.totalFat }
            contextParts.append("Today so far: \(Int(totalCal)) cal, \(Int(totalP))g protein, \(Int(totalC))g carbs, \(Int(totalF))g fat from \(todayMeals.count) meals")
        } else {
            contextParts.append("User hasn't logged any meals today yet.")
        }

        return contextParts.joined(separator: "\n")
    }
}
