import Foundation
import SwiftData

enum SyncOperation: String, Codable {
    case insert
    case update
    case delete
}

enum SyncStatus: String, Codable {
    case pending
    case inProgress
    case failed
    case completed
}

@Model
final class SyncRecord {
    @Attribute(.unique) var id: UUID
    var userId: String = ""
    var entityType: String
    var entityId: UUID
    var operationRaw: String
    var payloadData: Data?
    var statusRaw: String
    var attemptCount: Int
    var lastAttemptAt: Date?
    var errorMessage: String?
    var createdAt: Date

    var operation: SyncOperation {
        get { SyncOperation(rawValue: operationRaw) ?? .insert }
        set { operationRaw = newValue.rawValue }
    }

    var status: SyncStatus {
        get { SyncStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        entityType: String,
        entityId: UUID,
        operation: SyncOperation,
        payload: Data? = nil,
        status: SyncStatus = .pending,
        attemptCount: Int = 0,
        lastAttemptAt: Date? = nil,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.operationRaw = operation.rawValue
        self.payloadData = payload
        self.statusRaw = status.rawValue
        self.attemptCount = attemptCount
        self.lastAttemptAt = lastAttemptAt
        self.errorMessage = errorMessage
        self.createdAt = .now
    }
}
