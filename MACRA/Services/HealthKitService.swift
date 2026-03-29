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

    /// Check if user has previously authorized HealthKit (checks write permission for bodyMass as a proxy).
    nonisolated var hasBeenAuthorized: Bool {
        guard let store else { return false }
        // Check sharing authorization for bodyMass — if user granted write access, they went through the auth flow
        let status = store.authorizationStatus(for: HKQuantityType(.bodyMass))
        return status == .sharingAuthorized
    }

    func requestAuthorization() async -> Bool {
        guard let store else { return false }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass),
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryWater),
        ]

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.dietaryEnergyConsumed),
            HKQuantityType(.dietaryProtein),
            HKQuantityType(.dietaryFatTotal),
            HKQuantityType(.dietaryCarbohydrates),
            HKQuantityType(.dietaryWater),
            HKQuantityType(.bodyMass),
            HKWorkoutType.workoutType(),
        ]

        do {
            try await store.requestAuthorization(toShare: writeTypes, read: readTypes)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Write Methods

    func saveNutrition(calories: Double, protein: Double, carbs: Double, fat: Double, date: Date) async {
        guard let store else { return }
        var samples: [HKQuantitySample] = []

        let types: [(HKQuantityTypeIdentifier, HKUnit, Double)] = [
            (.dietaryEnergyConsumed, .kilocalorie(), calories),
            (.dietaryProtein, .gram(), protein),
            (.dietaryCarbohydrates, .gram(), carbs),
            (.dietaryFatTotal, .gram(), fat),
        ]

        for (id, unit, value) in types where value > 0 {
            let type = HKQuantityType(id)
            let quantity = HKQuantity(unit: unit, doubleValue: value)
            samples.append(HKQuantitySample(type: type, quantity: quantity, start: date, end: date))
        }

        guard !samples.isEmpty else { return }
        do {
            try await store.save(samples)
            #if DEBUG
            print("✅ HealthKit: wrote \(Int(calories)) cal, \(Int(protein))g P, \(Int(carbs))g C, \(Int(fat))g F")
            #endif
        } catch {
            #if DEBUG
            print("❌ HealthKit nutrition write failed: \(error.localizedDescription)")
            #endif
        }
    }

    func saveWater(oz: Double, date: Date) async {
        guard let store else { return }
        let type = HKQuantityType(.dietaryWater)
        // Convert oz to liters: 1 oz = 0.0295735 L
        let liters = oz * 0.0295735
        let quantity = HKQuantity(unit: .liter(), doubleValue: liters)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        do {
            try await store.save(sample)
            #if DEBUG
            print("✅ HealthKit: wrote \(oz) oz water")
            #endif
        } catch {
            #if DEBUG
            print("❌ HealthKit water write failed: \(error.localizedDescription)")
            #endif
        }
    }

    func saveWeight(lbs: Double, date: Date) async {
        guard let store else { return }
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .pound(), doubleValue: lbs)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        do {
            try await store.save(sample)
            #if DEBUG
            print("✅ HealthKit: wrote \(lbs) lbs weight")
            #endif
        } catch {
            #if DEBUG
            print("❌ HealthKit weight write failed: \(error.localizedDescription)")
            #endif
        }
    }

    func saveWorkout(name: String, activityType: HKWorkoutActivityType, durationMinutes: Int, caloriesBurned: Double, date: Date) async {
        guard let store else { return }

        let duration = TimeInterval(durationMinutes * 60)
        let startDate = date
        let endDate = date.addingTimeInterval(duration)
        let energyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: caloriesBurned)

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activityType

        do {
            let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: nil)
            try await builder.beginCollection(at: startDate)

            let energySample = HKQuantitySample(
                type: HKQuantityType(.activeEnergyBurned),
                quantity: energyBurned,
                start: startDate,
                end: endDate
            )
            try await builder.addSamples([energySample])
            try await builder.endCollection(at: endDate)
            try await builder.finishWorkout()
        } catch {
            // Silently fail — consistent with other save methods
        }
    }

    static func activityType(for name: String) -> HKWorkoutActivityType {
        switch name.lowercased() {
        case let n where n.contains("run") || n.contains("jog"):
            return .running
        case let n where n.contains("walk"):
            return .walking
        case let n where n.contains("weight") || n.contains("strength") || n.contains("dumbbell") || n.contains("barbell") || n.contains("lift"):
            return .traditionalStrengthTraining
        case let n where n.contains("cycl") || n.contains("bik"):
            return .cycling
        case let n where n.contains("swim"):
            return .swimming
        case let n where n.contains("basketball"):
            return .basketball
        case let n where n.contains("soccer") || n.contains("football"):
            return .soccer
        case let n where n.contains("tennis"):
            return .tennis
        case let n where n.contains("yoga"):
            return .yoga
        case let n where n.contains("pilates"):
            return .pilates
        case let n where n.contains("hiit") || n.contains("interval") || n.contains("circuit"):
            return .highIntensityIntervalTraining
        case let n where n.contains("hik"):
            return .hiking
        case let n where n.contains("row"):
            return .rowing
        case let n where n.contains("climb"):
            return .climbing
        case let n where n.contains("box") || n.contains("kickbox"):
            return .boxing
        case let n where n.contains("ski"):
            return .downhillSkiing
        case let n where n.contains("golf"):
            return .golf
        case let n where n.contains("danc"):
            return .socialDance
        case let n where n.contains("elliptical"):
            return .elliptical
        case let n where n.contains("jump rope") || n.contains("skipping"):
            return .jumpRope
        case let n where n.contains("stair"):
            return .stairClimbing
        case let n where n.contains("stretch") || n.contains("flexibility"):
            return .flexibility
        case let n where n.contains("crossfit") || n.contains("functional"):
            return .functionalStrengthTraining
        default:
            return .other
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
