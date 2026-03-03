import Foundation
import SwiftData

struct SyncRecordSnapshot: Sendable, Identifiable {
    let id: UUID
    let entityType: String
    let entityId: UUID
    let operation: SyncOperation
    let payload: Data?
    let status: SyncStatus
    let attemptCount: Int
    let createdAt: Date
}

protocol SyncEngineProtocol: Sendable {
    func pendingRecordCount() async throws -> Int
    func pendingRecords() async throws -> [SyncRecordSnapshot]
    func markInProgress(id: UUID) async throws
    func markCompleted(id: UUID) async throws
    func markFailed(id: UUID, error: String) async throws
    func cleanCompleted() async throws
}

@ModelActor
actor SyncEngine: SyncEngineProtocol {

    func pendingRecordCount() async throws -> Int {
        let pending = SyncStatus.pending.rawValue
        let failed = SyncStatus.failed.rawValue
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate<SyncRecord> { $0.statusRaw == pending || $0.statusRaw == failed }
        )
        return try modelContext.fetchCount(descriptor)
    }

    func pendingRecords() async throws -> [SyncRecordSnapshot] {
        let pending = SyncStatus.pending.rawValue
        let failed = SyncStatus.failed.rawValue
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate<SyncRecord> { $0.statusRaw == pending || $0.statusRaw == failed },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try modelContext.fetch(descriptor).map { record in
            SyncRecordSnapshot(
                id: record.id,
                entityType: record.entityType,
                entityId: record.entityId,
                operation: record.operation,
                payload: record.payloadData,
                status: record.status,
                attemptCount: record.attemptCount,
                createdAt: record.createdAt
            )
        }
    }

    func markInProgress(id: UUID) async throws {
        guard let record = try fetchRecord(id: id) else { return }
        record.status = .inProgress
        record.lastAttemptAt = .now
        record.attemptCount += 1
        try modelContext.save()
    }

    func markCompleted(id: UUID) async throws {
        guard let record = try fetchRecord(id: id) else { return }
        record.status = .completed
        try modelContext.save()
    }

    func markFailed(id: UUID, error: String) async throws {
        guard let record = try fetchRecord(id: id) else { return }
        record.status = .failed
        record.errorMessage = error
        try modelContext.save()
    }

    func cleanCompleted() async throws {
        let completed = SyncStatus.completed.rawValue
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate<SyncRecord> { $0.statusRaw == completed }
        )
        let records = try modelContext.fetch(descriptor)
        for record in records {
            modelContext.delete(record)
        }
        try modelContext.save()
    }

    // MARK: - Private

    private func fetchRecord(id: UUID) throws -> SyncRecord? {
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate<SyncRecord> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
