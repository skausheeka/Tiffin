import XCTest
import SwiftData
@testable import RecipeApp

final class MealPlanEntryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Recipe.self, MealPlanEntry.self, configurations: configuration)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func test_init_appliesDefaults() {
        let recipe = Recipe(title: "Dal")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = MealPlanEntry(date: date, recipe: recipe)

        XCTAssertEqual(entry.date, date)
        XCTAssertTrue(entry.recipe === recipe)
        XCTAssertNil(entry.servings)
        XCTAssertFalse(entry.expectsLeftovers)
    }

    func test_deletingRecipe_cascadesToItsMealPlanEntries() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = MealPlanEntry(date: .now, recipe: recipe)
        context.insert(entry)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MealPlanEntry>()), 1)

        context.delete(recipe)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<MealPlanEntry>()), 0)
    }

    func test_deletingMealPlanEntry_leavesRecipeIntact() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = MealPlanEntry(date: .now, recipe: recipe)
        context.insert(entry)
        try context.save()

        context.delete(entry)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Recipe>()), 1)
    }

    func test_recipeMealPlanEntries_reflectsInverseRelationship() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = MealPlanEntry(date: .now, recipe: recipe)
        context.insert(entry)
        try context.save()

        XCTAssertEqual(recipe.mealPlanEntries.count, 1)
        XCTAssertTrue(recipe.mealPlanEntries.first === entry)
    }
}
