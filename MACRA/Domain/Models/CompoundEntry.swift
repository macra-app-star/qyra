import Foundation
import SwiftData

@Model
final class CompoundEntry {
    var id: UUID
    var userId: String = ""
    var name: String
    var category: String
    var administrationMethod: String
    var dose: Double
    var unit: String
    var loggedAt: Date
    var notes: String?
    var site: String?
    var painLevel: Int?
    var createdAt: Date

    init(name: String, category: String, method: String, dose: Double, unit: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.administrationMethod = method
        self.dose = dose
        self.unit = unit
        self.loggedAt = .now
        self.createdAt = .now
    }
}

@Model
final class CompoundRegimen {
    var id: UUID
    var userId: String = ""
    var compoundName: String
    var category: String
    var method: String
    var standardDose: Double
    var unit: String
    var frequency: String
    var isActive: Bool
    var startDate: Date
    var notes: String?
    var reminderEnabled: Bool
    var reminderTime: Date
    var createdAt: Date

    init(name: String, category: String, method: String, dose: Double, unit: String, frequency: String) {
        self.id = UUID()
        self.compoundName = name
        self.category = category
        self.method = method
        self.standardDose = dose
        self.unit = unit
        self.frequency = frequency
        self.isActive = true
        self.startDate = .now
        self.reminderEnabled = false
        self.reminderTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? .now
        self.createdAt = .now
    }
}
