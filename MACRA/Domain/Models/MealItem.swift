import Foundation
import SwiftData

enum EntryMethod: String, Codable, CaseIterable {
    case manual
    case photo
    case barcode
    case voice
}

@Model
final class MealItem {
    @Attribute(.unique) var id: UUID
    var foodName: String
    var detailedBreakdown: String?
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sodium: Double?
    var servingSize: String?
    var confidenceScore: Int?
    var entryMethod: EntryMethod
    var barcode: String?
    var imageURL: String?
    var analysisNotes: String?
    var userVerified: Bool
    var createdAt: Date

    var mealLog: MealLog?

    init(
        id: UUID = UUID(),
        foodName: String,
        calories: Double = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fat: Double = 0,
        fiber: Double? = nil,
        sugar: Double? = nil,
        sodium: Double? = nil,
        servingSize: String? = nil,
        confidenceScore: Int? = nil,
        entryMethod: EntryMethod = .manual,
        barcode: String? = nil,
        imageURL: String? = nil,
        analysisNotes: String? = nil,
        detailedBreakdown: String? = nil,
        userVerified: Bool = false
    ) {
        self.id = id
        self.foodName = foodName
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.servingSize = servingSize
        self.confidenceScore = confidenceScore
        self.entryMethod = entryMethod
        self.barcode = barcode
        self.imageURL = imageURL
        self.analysisNotes = analysisNotes
        self.detailedBreakdown = detailedBreakdown
        self.userVerified = userVerified
        self.createdAt = .now
    }
}
