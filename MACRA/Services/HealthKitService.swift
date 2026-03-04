import Foundation
import HealthKit

@MainActor
final class HealthKitService: Sendable {
    static let shared = HealthKitService()

    nonisolated private let store: HKHealthStore?
    nonisolated let isAvailable: Bool

    nonisolated init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.store = HKHealthStore()
            self.isAvailable = true
        } else {
            self.store = nil
            self.isAvailable = false
        }
    }

    func requestAuthorization() async -> Bool {
        guard let store else { return false }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            return true
        } catch {
            return false
        }
    }

    func todaySteps() async -> Int {
        guard let store else { return 0 }
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        cont.resume(returning: sum)
                    }
                }
                store.execute(query)
            }
            return Int(result)
        } catch {
            return 0
        }
    }

    func todayActiveCalories() async -> Int {
        guard let store else { return 0 }
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: Date()),
            end: Date(),
            options: .strictStartDate
        )

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        let sum = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                        cont.resume(returning: sum)
                    }
                }
                store.execute(query)
            }
            return Int(result)
        } catch {
            return 0
        }
    }

    func steps(for date: Date) async -> Int {
        guard let store else { return 0 }
        let type = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    }
                }
                store.execute(query)
            }
            return Int(result)
        } catch {
            return 0
        }
    }

    func activeCalories(for date: Date) async -> Int {
        guard let store else { return 0 }
        let type = HKQuantityType(.activeEnergyBurned)
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? date
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: type,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0)
                    }
                }
                store.execute(query)
            }
            return Int(result)
        } catch {
            return 0
        }
    }
}
