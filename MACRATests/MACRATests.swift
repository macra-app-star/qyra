import XCTest
@testable import MACRA

// MARK: - Mock Repositories

struct MockMealRepository: MealRepositoryProtocol {
    var summaryToReturn: DailySummary = DailySummary(
        date: Date(),
        totalCalories: 800,
        totalProtein: 60,
        totalCarbs: 80,
        totalFat: 30,
        meals: [
            MealSummary(
                id: UUID(),
                mealType: .lunch,
                date: Date(),
                items: [
                    MealItemSummary(
                        id: UUID(),
                        foodName: "Chicken Breast",
                        calories: 300,
                        protein: 40,
                        carbs: 0,
                        fat: 8,
                        servingSize: "6 oz",
                        entryMethod: .manual
                    )
                ]
            )
        ]
    )
    var addMealCalled = false

    func fetchDailySummary(for date: Date) async throws -> DailySummary {
        summaryToReturn
    }

    func addMeal(date: Date, mealType: MealType, items: [NewMealItem]) async throws {}
    func deleteMeal(id: UUID) async throws {}
    func deleteMealItem(id: UUID) async throws {}
    func addItemToMeal(mealId: UUID, item: NewMealItem) async throws {}
}

struct MockGoalRepository: GoalRepositoryProtocol {
    var goalToReturn: MacroGoalSnapshot? = .default

    func fetchCurrentGoal() async throws -> MacroGoalSnapshot? {
        goalToReturn
    }

    func saveGoal(_ goal: MacroGoalSnapshot) async throws {}
}

// MARK: - Existing Tests

final class MACRATests: XCTestCase {

    func testMealSummaryTotals() {
        let items: [MealItemSummary] = [
            MealItemSummary(id: UUID(), foodName: "Rice", calories: 200, protein: 4, carbs: 45, fat: 1, servingSize: "1 cup", entryMethod: .manual),
            MealItemSummary(id: UUID(), foodName: "Chicken", calories: 300, protein: 40, carbs: 0, fat: 8, servingSize: nil, entryMethod: .manual),
        ]
        let meal = MealSummary(id: UUID(), mealType: .lunch, date: Date(), items: items)

        XCTAssertEqual(meal.totalCalories, 500)
        XCTAssertEqual(meal.totalProtein, 44)
        XCTAssertEqual(meal.totalCarbs, 45)
        XCTAssertEqual(meal.totalFat, 9)
        XCTAssertEqual(meal.displayDetail, "Rice, Chicken")
    }

    func testDefaultGoalValues() {
        let goal = MacroGoalSnapshot.default
        XCTAssertEqual(goal.dailyCalorieGoal, 2000)
        XCTAssertEqual(goal.dailyProteinGoal, 150)
        XCTAssertEqual(goal.dailyCarbGoal, 200)
        XCTAssertEqual(goal.dailyFatGoal, 65)
    }

    func testReconcileDayWithGoal() async throws {
        let mealRepo = MockMealRepository()
        let goalRepo = MockGoalRepository(goalToReturn: MacroGoalSnapshot(
            dailyCalorieGoal: 2500,
            dailyProteinGoal: 180,
            dailyCarbGoal: 250,
            dailyFatGoal: 80,
            activityLevel: .veryActive,
            goalType: .bulk
        ))

        let useCase = ReconcileDayUseCase(mealRepository: mealRepo, goalRepository: goalRepo)
        let result = try await useCase.execute(for: Date())

        XCTAssertEqual(result.summary.totalCalories, 800)
        XCTAssertEqual(result.goal.dailyCalorieGoal, 2500)
    }

    func testReconcileDayFallsBackToDefault() async throws {
        let mealRepo = MockMealRepository()
        let goalRepo = MockGoalRepository(goalToReturn: nil)

        let useCase = ReconcileDayUseCase(mealRepository: mealRepo, goalRepository: goalRepo)
        let result = try await useCase.execute(for: Date())

        XCTAssertEqual(result.goal, .default)
    }

    @MainActor
    func testDashboardViewModelLoads() async {
        let mealRepo = MockMealRepository()
        let goalRepo = MockGoalRepository()

        let useCase = ReconcileDayUseCase(mealRepository: mealRepo, goalRepository: goalRepo)
        let vm = DashboardViewModel(reconcileDay: useCase)

        await vm.loadDay()

        XCTAssertEqual(vm.currentCalories, 800)
        XCTAssertEqual(vm.currentProtein, 60)
        XCTAssertEqual(vm.calorieGoal, 2000)
        XCTAssertEqual(vm.proteinGoal, 150)
        XCTAssertEqual(vm.meals.count, 1)
        XCTAssertFalse(vm.isLoading)
    }

    @MainActor
    func testManualEntryCanSaveValidation() {
        let mealRepo = MockMealRepository()
        let vm = ManualEntryViewModel(mealRepository: mealRepo)

        XCTAssertFalse(vm.canSave)

        vm.foodName = "Test Food"
        XCTAssertFalse(vm.canSave)

        vm.caloriesText = "200"
        XCTAssertTrue(vm.canSave)

        vm.foodName = "   "
        XCTAssertFalse(vm.canSave)
    }
}

// MARK: - FoodAnalysisResult Tests

final class FoodAnalysisResultTests: XCTestCase {

    func testToNewMealItemMapsAllFields() {
        let result = FoodAnalysisResult(
            name: "Grilled Chicken",
            calories: 350,
            protein: 42,
            carbs: 2,
            fat: 15,
            fiber: 0.5,
            sugar: 0.2,
            sodium: 0.8,
            servingSize: "6 oz",
            confidence: 92,
            brand: "Tyson",
            barcode: "1234567890",
            imageURL: "https://example.com/chicken.jpg"
        )

        let item = result.toNewMealItem(entryMethod: .photo)

        XCTAssertEqual(item.foodName, "Grilled Chicken")
        XCTAssertEqual(item.calories, 350)
        XCTAssertEqual(item.protein, 42)
        XCTAssertEqual(item.carbs, 2)
        XCTAssertEqual(item.fat, 15)
        XCTAssertEqual(item.fiber, 0.5)
        XCTAssertEqual(item.sugar, 0.2)
        XCTAssertEqual(item.sodium, 0.8)
        XCTAssertEqual(item.servingSize, "6 oz")
        XCTAssertEqual(item.entryMethod, .photo)
        XCTAssertEqual(item.confidenceScore, 92)
        XCTAssertEqual(item.barcode, "1234567890")
        XCTAssertEqual(item.imageURL, "https://example.com/chicken.jpg")
    }

    func testToNewMealItemWithBarcodeEntry() {
        let result = FoodAnalysisResult(
            name: "Protein Bar",
            calories: 200,
            protein: 20,
            carbs: 25,
            fat: 8,
            servingSize: "1 bar",
            confidence: 95,
            barcode: "0049000042566"
        )

        let item = result.toNewMealItem(entryMethod: .barcode)

        XCTAssertEqual(item.entryMethod, .barcode)
        XCTAssertEqual(item.barcode, "0049000042566")
        XCTAssertNil(item.imageURL)
    }

    func testToNewMealItemWithVoiceEntry() {
        let result = FoodAnalysisResult(
            name: "Caesar Salad",
            calories: 450,
            protein: 20,
            carbs: 15,
            fat: 35,
            confidence: 70
        )

        let item = result.toNewMealItem(entryMethod: .voice)

        XCTAssertEqual(item.entryMethod, .voice)
        XCTAssertEqual(item.confidenceScore, 70)
        XCTAssertNil(item.fiber)
        XCTAssertNil(item.sugar)
        XCTAssertNil(item.sodium)
        XCTAssertNil(item.servingSize)
        XCTAssertNil(item.barcode)
    }

    func testDefaultConfidence() {
        let result = FoodAnalysisResult(
            name: "Apple",
            calories: 95,
            protein: 0.5,
            carbs: 25,
            fat: 0.3
        )

        XCTAssertEqual(result.confidence, 80) // Default
    }

    func testEquatable() {
        let id = UUID()
        let a = FoodAnalysisResult(id: id, name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4)
        let b = FoodAnalysisResult(id: id, name: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4)

        XCTAssertEqual(a, b)
    }

    func testIdentifiable() {
        let result = FoodAnalysisResult(name: "Egg", calories: 70, protein: 6, carbs: 0.6, fat: 5)
        XCTAssertNotNil(result.id)
    }
}

// MARK: - USDAFoodResult Tests

final class USDAFoodResultTests: XCTestCase {

    func testToFoodAnalysisResult() {
        let usda = USDAFoodResult(
            id: 12345,
            name: "Chicken Breast, Grilled",
            brand: "Perdue",
            calories: 165,
            protein: 31,
            carbs: 0,
            fat: 3.6,
            fiber: 0,
            sugar: 0,
            sodium: 0.074,
            servingSize: "3 oz",
            servingWeight: 85,
            dataType: "Branded"
        )

        let result = usda.toFoodAnalysisResult()

        XCTAssertEqual(result.name, "Chicken Breast, Grilled")
        XCTAssertEqual(result.calories, 165)
        XCTAssertEqual(result.protein, 31)
        XCTAssertEqual(result.carbs, 0)
        XCTAssertEqual(result.fat, 3.6)
        XCTAssertEqual(result.fiber, 0)
        XCTAssertEqual(result.sugar, 0)
        XCTAssertEqual(result.sodium, 0.074)
        XCTAssertEqual(result.servingSize, "3 oz")
        XCTAssertEqual(result.confidence, 95)
        XCTAssertEqual(result.brand, "Perdue")
    }

    func testToFoodAnalysisResultDefaultServing() {
        let usda = USDAFoodResult(
            id: 67890,
            name: "Brown Rice",
            brand: nil,
            calories: 112,
            protein: 2.3,
            carbs: 23.5,
            fat: 0.8,
            fiber: 1.8,
            sugar: 0.4,
            sodium: nil,
            servingSize: nil,
            servingWeight: nil,
            dataType: "Foundation"
        )

        let result = usda.toFoodAnalysisResult()

        XCTAssertEqual(result.servingSize, "100g") // Fallback
        XCTAssertNil(result.brand)
        XCTAssertNil(result.sodium) // nil passes through
    }

    func testUSDAFoodResultEquatable() {
        let a = USDAFoodResult(id: 100, name: "Apple", brand: nil, calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4, sugar: 19, sodium: nil, servingSize: "1 medium", servingWeight: 182, dataType: "SR Legacy")
        let b = USDAFoodResult(id: 100, name: "Apple", brand: nil, calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4, sugar: 19, sodium: nil, servingSize: "1 medium", servingWeight: 182, dataType: "SR Legacy")

        XCTAssertEqual(a, b)
    }
}

// MARK: - NewMealItem Tests

final class NewMealItemTests: XCTestCase {

    func testDefaultInitialization() {
        let item = NewMealItem(
            foodName: "Test",
            calories: 100,
            protein: 10,
            carbs: 20,
            fat: 5
        )

        XCTAssertEqual(item.foodName, "Test")
        XCTAssertEqual(item.calories, 100)
        XCTAssertEqual(item.protein, 10)
        XCTAssertEqual(item.carbs, 20)
        XCTAssertEqual(item.fat, 5)
        XCTAssertNil(item.fiber)
        XCTAssertNil(item.sugar)
        XCTAssertNil(item.sodium)
        XCTAssertNil(item.servingSize)
        XCTAssertEqual(item.entryMethod, .manual) // Default
        XCTAssertNil(item.confidenceScore)
        XCTAssertNil(item.barcode)
        XCTAssertNil(item.imageURL)
    }

    func testFullInitialization() {
        let item = NewMealItem(
            foodName: "Scanned Bar",
            calories: 220,
            protein: 15,
            carbs: 30,
            fat: 9,
            fiber: 3.5,
            sugar: 12,
            sodium: 0.35,
            servingSize: "1 bar (60g)",
            entryMethod: .barcode,
            confidenceScore: 95,
            barcode: "0049000042566",
            imageURL: "https://images.openfoodfacts.org/1234.jpg"
        )

        XCTAssertEqual(item.foodName, "Scanned Bar")
        XCTAssertEqual(item.fiber, 3.5)
        XCTAssertEqual(item.sugar, 12)
        XCTAssertEqual(item.sodium, 0.35)
        XCTAssertEqual(item.entryMethod, .barcode)
        XCTAssertEqual(item.confidenceScore, 95)
        XCTAssertEqual(item.barcode, "0049000042566")
        XCTAssertEqual(item.imageURL, "https://images.openfoodfacts.org/1234.jpg")
    }

    func testPhotoEntryMethod() {
        let item = NewMealItem(
            foodName: "Pasta",
            calories: 400,
            protein: 12,
            carbs: 60,
            fat: 14,
            entryMethod: .photo,
            confidenceScore: 75
        )

        XCTAssertEqual(item.entryMethod, .photo)
        XCTAssertEqual(item.confidenceScore, 75)
    }

    func testVoiceEntryMethod() {
        let item = NewMealItem(
            foodName: "Burrito",
            calories: 550,
            protein: 25,
            carbs: 55,
            fat: 22,
            entryMethod: .voice,
            confidenceScore: 65
        )

        XCTAssertEqual(item.entryMethod, .voice)
        XCTAssertEqual(item.confidenceScore, 65)
    }
}

// MARK: - MealType Tests

final class MealTypeTests: XCTestCase {

    func testMealTypeDisplayNames() {
        XCTAssertEqual(MealType.breakfast.displayName, "Breakfast")
        XCTAssertEqual(MealType.lunch.displayName, "Lunch")
        XCTAssertEqual(MealType.dinner.displayName, "Dinner")
        XCTAssertEqual(MealType.snack.displayName, "Snack")
    }

    func testMealTypeIcons() {
        XCTAssertFalse(MealType.breakfast.icon.isEmpty)
        XCTAssertFalse(MealType.lunch.icon.isEmpty)
        XCTAssertFalse(MealType.dinner.icon.isEmpty)
        XCTAssertFalse(MealType.snack.icon.isEmpty)
    }
}

// MARK: - APIError Tests

final class APIErrorTests: XCTestCase {

    func testErrorDescriptions() {
        XCTAssertEqual(APIError.invalidURL.errorDescription, "Invalid URL")
        XCTAssertEqual(APIError.invalidResponse(statusCode: 500).errorDescription, "Server error (HTTP 500)")
        XCTAssertEqual(APIError.noData.errorDescription, "No data received")
        XCTAssertEqual(APIError.rateLimited.errorDescription, "Rate limit exceeded. Try again shortly.")
        XCTAssertEqual(APIError.unauthorized.errorDescription, "Invalid API key")
    }

    func testDecodingFailedDescription() {
        let innerError = NSError(domain: "test", code: 1, userInfo: nil)
        let error = APIError.decodingFailed(innerError)
        XCTAssertEqual(error.errorDescription, "Failed to parse response")
    }
}

// MARK: - FoodSearchViewModel Tests

@MainActor
final class FoodSearchViewModelTests: XCTestCase {

    func testAutoSelectsMealTypeByTimeOfDay() {
        let mealRepo = MockMealRepository()
        let vm = FoodSearchViewModel(mealRepository: mealRepo)

        // Meal type should be auto-selected based on current hour
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<11:
            XCTAssertEqual(vm.selectedMealType, .breakfast)
        case 11..<15:
            XCTAssertEqual(vm.selectedMealType, .lunch)
        case 15..<21:
            XCTAssertEqual(vm.selectedMealType, .dinner)
        default:
            XCTAssertEqual(vm.selectedMealType, .snack)
        }
    }

    func testSearchRequiresMinimumCharacters() {
        let mealRepo = MockMealRepository()
        let vm = FoodSearchViewModel(mealRepository: mealRepo)

        vm.searchText = "a"
        vm.onSearchTextChanged()

        // Results should be empty for single character
        XCTAssertTrue(vm.results.isEmpty)
    }

    func testClearRecentSearches() {
        let mealRepo = MockMealRepository()
        let vm = FoodSearchViewModel(mealRepository: mealRepo)

        vm.clearRecentSearches()
        XCTAssertTrue(vm.recentSearches.isEmpty)
    }

    func testInitialState() {
        let mealRepo = MockMealRepository()
        let vm = FoodSearchViewModel(mealRepository: mealRepo)

        XCTAssertEqual(vm.searchText, "")
        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.isSearching)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.didSave)
    }
}

// MARK: - End-to-End DTO Pipeline Tests

final class DTOPipelineTests: XCTestCase {

    func testUSDAToFoodAnalysisToNewMealItem() {
        // Simulate full pipeline: USDA result → FoodAnalysisResult → NewMealItem
        let usda = USDAFoodResult(
            id: 55555,
            name: "Salmon, Atlantic",
            brand: nil,
            calories: 208,
            protein: 20.4,
            carbs: 0,
            fat: 13.4,
            fiber: nil,
            sugar: nil,
            sodium: 0.059,
            servingSize: "3 oz",
            servingWeight: 85,
            dataType: "SR Legacy"
        )

        let analysis = usda.toFoodAnalysisResult()
        let mealItem = analysis.toNewMealItem(entryMethod: .manual)

        // Verify full pipeline preserves data
        XCTAssertEqual(mealItem.foodName, "Salmon, Atlantic")
        XCTAssertEqual(mealItem.calories, 208)
        XCTAssertEqual(mealItem.protein, 20.4)
        XCTAssertEqual(mealItem.carbs, 0)
        XCTAssertEqual(mealItem.fat, 13.4)
        XCTAssertNil(mealItem.fiber)
        XCTAssertNil(mealItem.sugar)
        XCTAssertEqual(mealItem.sodium, 0.059)
        XCTAssertEqual(mealItem.servingSize, "3 oz")
        XCTAssertEqual(mealItem.entryMethod, .manual)
        XCTAssertEqual(mealItem.confidenceScore, 95) // USDA confidence
        XCTAssertNil(mealItem.barcode)
    }

    func testPhotoAnalysisPipeline() {
        // Simulate Gemini photo result → NewMealItem
        let geminiResult = FoodAnalysisResult(
            name: "Grilled Steak",
            calories: 614,
            protein: 58,
            carbs: 0,
            fat: 41,
            fiber: nil,
            servingSize: "8 oz",
            confidence: 85
        )

        let item = geminiResult.toNewMealItem(entryMethod: .photo)

        XCTAssertEqual(item.foodName, "Grilled Steak")
        XCTAssertEqual(item.entryMethod, .photo)
        XCTAssertEqual(item.confidenceScore, 85)
    }

    func testBarcodePipeline() {
        // Simulate OpenFoodFacts barcode result → NewMealItem
        let barcodeResult = FoodAnalysisResult(
            name: "Organic Oat Milk",
            calories: 120,
            protein: 3,
            carbs: 16,
            fat: 5,
            fiber: 2,
            sugar: 7,
            sodium: 0.1,
            servingSize: "1 cup (240ml)",
            confidence: 90,
            brand: "Oatly",
            barcode: "7394376616037",
            imageURL: "https://images.openfoodfacts.org/oatly.jpg"
        )

        let item = barcodeResult.toNewMealItem(entryMethod: .barcode)

        XCTAssertEqual(item.foodName, "Organic Oat Milk")
        XCTAssertEqual(item.entryMethod, .barcode)
        XCTAssertEqual(item.barcode, "7394376616037")
        XCTAssertEqual(item.imageURL, "https://images.openfoodfacts.org/oatly.jpg")
        XCTAssertEqual(item.confidenceScore, 90)
        XCTAssertEqual(item.fiber, 2)
        XCTAssertEqual(item.sugar, 7)
    }

    func testVoicePipeline() {
        // Simulate voice transcription → Gemini NLP → NewMealItem
        let voiceResult = FoodAnalysisResult(
            name: "Chicken Burrito",
            calories: 580,
            protein: 28,
            carbs: 55,
            fat: 24,
            fiber: 6,
            servingSize: "1 large burrito",
            confidence: 72
        )

        let item = voiceResult.toNewMealItem(entryMethod: .voice)

        XCTAssertEqual(item.foodName, "Chicken Burrito")
        XCTAssertEqual(item.entryMethod, .voice)
        XCTAssertEqual(item.confidenceScore, 72)
        XCTAssertEqual(item.fiber, 6)
        XCTAssertNil(item.sugar)
    }
}

// MARK: - MealSummary Edge Cases

final class MealSummaryEdgeCaseTests: XCTestCase {

    func testEmptyItemsList() {
        let meal = MealSummary(id: UUID(), mealType: .breakfast, date: Date(), items: [])

        XCTAssertEqual(meal.totalCalories, 0)
        XCTAssertEqual(meal.totalProtein, 0)
        XCTAssertEqual(meal.totalCarbs, 0)
        XCTAssertEqual(meal.totalFat, 0)
        XCTAssertEqual(meal.displayDetail, "")
    }

    func testSingleItem() {
        let items = [
            MealItemSummary(id: UUID(), foodName: "Banana", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, servingSize: "1 medium", entryMethod: .manual)
        ]
        let meal = MealSummary(id: UUID(), mealType: .snack, date: Date(), items: items)

        XCTAssertEqual(meal.totalCalories, 105)
        XCTAssertEqual(meal.displayDetail, "Banana")
    }

    func testManyItems() {
        let items = (1...5).map { i in
            MealItemSummary(
                id: UUID(),
                foodName: "Food \(i)",
                calories: Double(i * 100),
                protein: Double(i * 10),
                carbs: Double(i * 15),
                fat: Double(i * 5),
                servingSize: nil,
                entryMethod: .manual
            )
        }
        let meal = MealSummary(id: UUID(), mealType: .dinner, date: Date(), items: items)

        XCTAssertEqual(meal.totalCalories, 1500) // 100+200+300+400+500
        XCTAssertEqual(meal.totalProtein, 150)   // 10+20+30+40+50
    }

    func testMixedEntryMethods() {
        let items = [
            MealItemSummary(id: UUID(), foodName: "Photo Food", calories: 300, protein: 20, carbs: 30, fat: 10, servingSize: nil, entryMethod: .photo),
            MealItemSummary(id: UUID(), foodName: "Scanned Food", calories: 200, protein: 15, carbs: 20, fat: 8, servingSize: nil, entryMethod: .barcode),
            MealItemSummary(id: UUID(), foodName: "Voice Food", calories: 400, protein: 25, carbs: 40, fat: 15, servingSize: nil, entryMethod: .voice),
        ]
        let meal = MealSummary(id: UUID(), mealType: .lunch, date: Date(), items: items)

        XCTAssertEqual(meal.totalCalories, 900)
        XCTAssertEqual(meal.displayDetail, "Photo Food, Scanned Food, Voice Food")
    }
}
