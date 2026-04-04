import Foundation
import SwiftData

@Observable
final class AIChatHistoryViewModel {
    var conversations: [AIConversation] = []
    var isLoading: Bool = false

    struct ConversationGroup: Identifiable {
        let id: String
        let title: String
        let conversations: [AIConversation]
    }

    var groupedConversations: [ConversationGroup] {
        let calendar = Calendar.current
        let now = Date()

        var today: [AIConversation] = []
        var yesterday: [AIConversation] = []
        var thisWeek: [AIConversation] = []
        var thisMonth: [AIConversation] = []
        var earlier: [AIConversation] = []

        for convo in conversations {
            if calendar.isDateInToday(convo.updatedAt) {
                today.append(convo)
            } else if calendar.isDateInYesterday(convo.updatedAt) {
                yesterday.append(convo)
            } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                      convo.updatedAt >= weekAgo {
                thisWeek.append(convo)
            } else if let monthAgo = calendar.date(byAdding: .day, value: -30, to: now),
                      convo.updatedAt >= monthAgo {
                thisMonth.append(convo)
            } else {
                earlier.append(convo)
            }
        }

        var groups: [ConversationGroup] = []
        if !today.isEmpty { groups.append(ConversationGroup(id: "today", title: "Today", conversations: today)) }
        if !yesterday.isEmpty { groups.append(ConversationGroup(id: "yesterday", title: "Yesterday", conversations: yesterday)) }
        if !thisWeek.isEmpty { groups.append(ConversationGroup(id: "thisWeek", title: "This Week", conversations: thisWeek)) }
        if !thisMonth.isEmpty { groups.append(ConversationGroup(id: "thisMonth", title: "This Month", conversations: thisMonth)) }
        if !earlier.isEmpty { groups.append(ConversationGroup(id: "earlier", title: "Earlier", conversations: earlier)) }
        return groups
    }

    func loadConversations(modelContext: ModelContext) {
        isLoading = true
        var descriptor = FetchDescriptor<AIConversation>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 100
        conversations = (try? modelContext.fetch(descriptor)) ?? []
        isLoading = false
    }

    func deleteConversation(_ conversation: AIConversation, modelContext: ModelContext) {
        modelContext.delete(conversation)
        try? modelContext.save()
        conversations.removeAll { $0.id == conversation.id }
    }

    func createNewConversation() -> UUID {
        return UUID()
    }

    static func relativeTimeString(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let diff = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let minutes = diff.minute, let hours = diff.hour, let days = diff.day {
            if days == 0 && hours == 0 && minutes < 60 {
                return "\(max(1, minutes))m"
            } else if days == 0 && hours < 24 {
                return "\(hours)h"
            } else if calendar.isDateInYesterday(date) {
                return "Yesterday"
            } else if days < 7 {
                let formatter = DateFormatter()
                formatter.dateFormat = "EEEE"
                return formatter.string(from: date)
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }

        return ""
    }
}
