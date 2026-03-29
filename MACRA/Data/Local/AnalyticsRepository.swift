import Foundation
import SwiftData

@ModelActor
actor AnalyticsRepository {

    func recordEvent(
        name: String,
        properties: [String: String] = [:],
        sessionId: String,
        userId: String? = nil
    ) throws {
        let event = AnalyticsEvent(
            name: name,
            properties: properties,
            sessionId: sessionId,
            userId: userId
        )
        modelContext.insert(event)
        try modelContext.save()
    }

    func pendingEvents(limit: Int = 50) throws -> [AnalyticsEvent] {
        var descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { !$0.isSynced },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    func markSynced(ids: [UUID]) throws {
        for id in ids {
            let descriptor = FetchDescriptor<AnalyticsEvent>(
                predicate: #Predicate { $0.id == id }
            )
            if let event = try modelContext.fetch(descriptor).first {
                event.isSynced = true
            }
        }
        try modelContext.save()
    }

    func purgeOldSyncedEvents(olderThan days: Int = 30) throws {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { $0.isSynced && $0.timestamp < cutoff }
        )
        let old = try modelContext.fetch(descriptor)
        for event in old {
            modelContext.delete(event)
        }
        try modelContext.save()
    }

    func totalUnsyncedCount() throws -> Int {
        let descriptor = FetchDescriptor<AnalyticsEvent>(
            predicate: #Predicate { !$0.isSynced }
        )
        return try modelContext.fetchCount(descriptor)
    }
}
