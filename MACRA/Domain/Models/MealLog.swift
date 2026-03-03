import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "leaf.fill"
        }
    }
}

@Model
final class MealLog {
    @Attribute(.unique) var id: UUID
    var userId: String
    var date: Date
    var mealType: MealType
    var createdAt: Date
    var updatedAt: Date
    var isSynced: Bool
    var remoteId: String?

    @Relationship(deleteRule: .cascade, inverse: \MealItem.mealLog)
    var items: [MealItem]

    var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        items.reduce(0) { $0 + $1.protein }
    }

    var totalCarbs: Double {
        items.reduce(0) { $0 + $1.carbs }
    }

    var totalFat: Double {
        items.reduce(0) { $0 + $1.fat }
    }

    init(
        id: UUID = UUID(),
        userId: String = "",
        date: Date = .now,
        mealType: MealType = .lunch,
        items: [MealItem] = [],
        isSynced: Bool = false,
        remoteId: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.date = Calendar.current.startOfDay(for: date)
        self.mealType = mealType
        self.items = items
        self.createdAt = .now
        self.updatedAt = .now
        self.isSynced = isSynced
        self.remoteId = remoteId
    }
}
