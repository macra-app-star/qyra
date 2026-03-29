import Foundation
import SwiftData
import os

@ModelActor
actor DataMigrationService {

    private let logger = Logger(subsystem: "co.tamras.qyra", category: "Migration")

    /// Tags all untagged records (userId == "") with the provided userId.
    /// Safe to call multiple times — only touches records with empty userId.
    func tagUnownedRecords(with userId: String) {
        let migrationKey = "data_migration_tagged_\(userId)"

        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            logger.info("Data migration already complete for user \(userId)")
            return
        }

        logger.info("Starting data migration: tagging unowned records for user \(userId)")

        var totalTagged = 0

        totalTagged += tagRecords(MealLog.self, userId: userId)
        totalTagged += tagRecords(MealItem.self, userId: userId)
        totalTagged += tagRecords(ExerciseEntry.self, userId: userId)
        totalTagged += tagRecords(WeightEntry.self, userId: userId)
        totalTagged += tagRecords(WaterEntry.self, userId: userId)
        totalTagged += tagRecords(CaffeineEntry.self, userId: userId)
        totalTagged += tagRecords(FastingSession.self, userId: userId)
        totalTagged += tagRecords(CompoundEntry.self, userId: userId)
        totalTagged += tagRecords(CompoundRegimen.self, userId: userId)
        totalTagged += tagRecords(QuickMeal.self, userId: userId)
        totalTagged += tagRecords(ProgressPhoto.self, userId: userId)
        totalTagged += tagRecords(VersusChallenge.self, userId: userId)
        totalTagged += tagRecords(SyncRecord.self, userId: userId)

        try? modelContext.save()

        UserDefaults.standard.set(true, forKey: migrationKey)
        logger.info("Data migration complete. Tagged \(totalTagged) records for user \(userId)")
    }

    /// Generic per-type tagging. SwiftData doesn't support generic predicates well,
    /// so we fetch ALL records and filter in memory for empty userId.
    private func tagRecords<T: PersistentModel>(_ type: T.Type, userId: String) -> Int {
        let descriptor = FetchDescriptor<T>()
        guard let records = try? modelContext.fetch(descriptor) else { return 0 }

        var count = 0
        for record in records {
            // Use KVC-style access since we can't use generic protocol constraints with @Model
            if let userIdValue = (record as AnyObject).value(forKey: "userId") as? String,
               userIdValue.isEmpty {
                (record as AnyObject).setValue(userId, forKey: "userId")
                count += 1
            }
        }
        return count
    }
}
