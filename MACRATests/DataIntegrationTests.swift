import XCTest
import SwiftData
@testable import MACRA

// MARK: - FoodProduct Tests

final class FoodProductTests: XCTestCase {

    func testFoodProductInit() {
        let product = FoodProduct(
            barcode: "1234567890123",
            name: "Test Granola Bar",
            brands: "Nature Valley",
            caloriesPer100g: 450,
            proteinPer100g: 8,
            carbsPer100g: 65,
            fatPer100g: 18,
            fiberPer100g: 3.5,
            sugarPer100g: 28,
            servingSize: "1 bar (42g)",
            servingSizeGrams: 42,
            nutriScore: "C",
            source: "openfoodfacts"
        )

        XCTAssertEqual(product.barcode, "1234567890123")
        XCTAssertEqual(product.name, "Test Granola Bar")
        XCTAssertEqual(product.brands, "Nature Valley")
        XCTAssertEqual(product.caloriesPer100g, 450)
        XCTAssertEqual(product.nutriScore, "C")
        XCTAssertEqual(product.searchName, "test granola bar")
    }

    func testFoodProductToFoodAnalysisResult() {
        let product = FoodProduct(
            barcode: "9876543210",
            name: "Organic Yogurt",
            brands: "Chobani",
            caloriesPer100g: 100,
            proteinPer100g: 15,
            carbsPer100g: 8,
            fatPer100g: 2,
            servingSize: "1 cup (170g)",
            servingSizeGrams: 170,
            source: "usda"
        )

        let result = product.toFoodAnalysisResult()

        // Should scale to serving size (170g)
        XCTAssertEqual(result.name, "Organic Yogurt")
        XCTAssertEqual(result.calories, 170, accuracy: 0.1) // 100 * 1.7
        XCTAssertEqual(result.protein, 25.5, accuracy: 0.1) // 15 * 1.7
        XCTAssertEqual(result.carbs, 13.6, accuracy: 0.1)   // 8 * 1.7
        XCTAssertEqual(result.fat, 3.4, accuracy: 0.1)      // 2 * 1.7
        XCTAssertEqual(result.confidence, 90)
        XCTAssertEqual(result.brand, "Chobani")
        XCTAssertEqual(result.barcode, "9876543210")
    }

    func testFoodProductDefaultServing() {
        let product = FoodProduct(
            barcode: "0000000000",
            name: "Generic Rice",
            caloriesPer100g: 130,
            proteinPer100g: 2.7,
            carbsPer100g: 28,
            fatPer100g: 0.3,
            source: "usda"
        )

        let result = product.toFoodAnalysisResult()

        // No serving size → defaults to 100g scale (1.0x)
        XCTAssertEqual(result.calories, 130)
        XCTAssertEqual(result.servingSize, "100g")
    }
}

// MARK: - Exercise Tests

final class ExerciseTests: XCTestCase {

    func testExerciseInit() {
        let exercise = Exercise(
            externalId: "bench-press-001",
            name: "Barbell Bench Press",
            bodyPart: "chest",
            targetMuscle: "pectorals",
            secondaryMuscles: ["anterior deltoids", "triceps"],
            equipment: "barbell",
            instructions: ["Lie on bench", "Grip bar", "Lower to chest", "Press up"],
            metValue: 6.0,
            source: "exercisedb"
        )

        XCTAssertEqual(exercise.externalId, "bench-press-001")
        XCTAssertEqual(exercise.name, "Barbell Bench Press")
        XCTAssertEqual(exercise.bodyPart, "chest")
        XCTAssertEqual(exercise.targetMuscle, "pectorals")
        XCTAssertEqual(exercise.secondaryMuscles.count, 2)
        XCTAssertEqual(exercise.equipment, "barbell")
        XCTAssertEqual(exercise.instructions.count, 4)
        XCTAssertEqual(exercise.metValue, 6.0)
        XCTAssertFalse(exercise.isFavorite)
        XCTAssertEqual(exercise.searchName, "barbell bench press")
    }

    func testBodyPartCategoryIcon() {
        XCTAssertEqual(BodyPartCategory.chest.icon, "figure.arms.open")
        XCTAssertEqual(BodyPartCategory.back.icon, "figure.strengthtraining.traditional")
        XCTAssertEqual(BodyPartCategory.cardio.icon, "heart.fill")
    }

    func testBodyPartCategoryDisplayName() {
        XCTAssertEqual(BodyPartCategory.lowerArms.displayName, "Lower arms")
        XCTAssertEqual(BodyPartCategory.upperLegs.displayName, "Upper legs")
    }
}

// MARK: - FoodPrediction Tests

final class FoodPredictionTests: XCTestCase {

    func testDisplayName() {
        let prediction = FoodPrediction(label: "grilled_chicken_breast", confidence: 0.92)
        XCTAssertEqual(prediction.displayName, "Grilled Chicken Breast")
    }

    func testConfidencePercent() {
        let prediction = FoodPrediction(label: "pizza", confidence: 0.87)
        XCTAssertEqual(prediction.confidencePercent, 87)
    }

    func testLowConfidence() {
        let prediction = FoodPrediction(label: "unknown", confidence: 0.12)
        XCTAssertEqual(prediction.confidencePercent, 12)
    }
}

// MARK: - FormQuality Tests

final class FormQualityTests: XCTestCase {

    func testComparable() {
        XCTAssertTrue(FormQuality.poor < FormQuality.fair)
        XCTAssertTrue(FormQuality.fair < FormQuality.good)
        XCTAssertTrue(FormQuality.unknown < FormQuality.poor)
    }

    func testLabels() {
        XCTAssertEqual(FormQuality.good.label, "Great form")
        XCTAssertEqual(FormQuality.fair.label, "Getting there")
        XCTAssertEqual(FormQuality.poor.label, "Needs work")
    }
}

// MARK: - ExerciseImport JSON Parsing Tests

final class ExerciseImportParsingTests: XCTestCase {

    func testFreeExerciseDBJSONDecoding() throws {
        let json = """
        [
            {
                "id": "test-001",
                "name": "Push-up",
                "category": "strength",
                "primaryMuscles": ["chest"],
                "secondaryMuscles": ["triceps", "shoulders"],
                "equipment": "body only",
                "instructions": ["Get in plank position", "Lower body", "Push back up"],
                "level": "beginner"
            }
        ]
        """.data(using: .utf8)!

        struct FreeExerciseDTO: Codable {
            let id: String?
            let name: String
            let category: String?
            let primaryMuscles: [String]?
            let secondaryMuscles: [String]?
            let equipment: String?
            let instructions: [String]?
            let level: String?
        }

        let decoded = try JSONDecoder().decode([FreeExerciseDTO].self, from: json)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, "Push-up")
        XCTAssertEqual(decoded[0].primaryMuscles?.first, "chest")
        XCTAssertEqual(decoded[0].secondaryMuscles?.count, 2)
        XCTAssertEqual(decoded[0].instructions?.count, 3)
    }

    func testExerciseDBExpandedJSONDecoding() throws {
        let json = """
        [
            {
                "id": "0001",
                "name": "3/4 sit-up",
                "bodyPart": "waist",
                "target": "abs",
                "secondaryMuscles": ["hip flexors"],
                "equipment": "body weight",
                "instructions": ["Lie on back", "Crunch up 3/4 of the way"],
                "gifUrl": "https://example.com/situp.gif"
            }
        ]
        """.data(using: .utf8)!

        struct ExerciseDBDTO: Codable {
            let id: String?
            let name: String
            let bodyPart: String?
            let target: String?
            let secondaryMuscles: [String]?
            let equipment: String?
            let instructions: [String]?
            let gifUrl: String?
        }

        let decoded = try JSONDecoder().decode([ExerciseDBDTO].self, from: json)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded[0].name, "3/4 sit-up")
        XCTAssertEqual(decoded[0].bodyPart, "waist")
        XCTAssertEqual(decoded[0].target, "abs")
        XCTAssertNotNil(decoded[0].gifUrl)
    }
}
