import XCTest
import SwiftData
@testable import RecipeApp

final class CookingLogEntryTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Recipe.self, CookingLogEntry.self, configurations: configuration)
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func test_init_appliesDefaults() {
        let recipe = Recipe(title: "Dal")
        let entry = CookingLogEntry(rating: 4, recipe: recipe)

        XCTAssertEqual(entry.rating, 4)
        XCTAssertNil(entry.note)
        XCTAssertTrue(entry.recipe === recipe)
    }

    func test_init_acceptsExplicitDateAndNote() {
        let recipe = Recipe(title: "Dal")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = CookingLogEntry(date: date, rating: 3, note: "too salty", recipe: recipe)

        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.note, "too salty")
    }

    func test_deletingRecipe_cascadesToItsCookingLogEntries() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = CookingLogEntry(rating: 5, recipe: recipe)
        context.insert(entry)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CookingLogEntry>()), 1)

        context.delete(recipe)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<CookingLogEntry>()), 0)
    }

    func test_deletingCookingLogEntry_leavesRecipeIntact() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = CookingLogEntry(rating: 5, recipe: recipe)
        context.insert(entry)
        try context.save()

        context.delete(entry)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Recipe>()), 1)
    }

    func test_recipeCookingLogEntries_reflectsInverseRelationship() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = CookingLogEntry(rating: 5, recipe: recipe)
        context.insert(entry)
        try context.save()

        XCTAssertEqual(recipe.cookingLogEntries.count, 1)
        XCTAssertTrue(recipe.cookingLogEntries.first === entry)
    }

    func test_averageRating_isNilWithNoEntries() {
        let recipe = Recipe(title: "Dal")

        XCTAssertNil(recipe.averageRating)
    }

    func test_averageRating_matchesSingleEntry() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        context.insert(CookingLogEntry(rating: 4, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.averageRating, 4.0)
    }

    func test_averageRating_isMeanAcrossMultipleEntries() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        context.insert(CookingLogEntry(rating: 5, recipe: recipe))
        context.insert(CookingLogEntry(rating: 4, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.averageRating, 4.5)
    }

    func test_timesCooked_reflectsEntryCount() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        XCTAssertEqual(recipe.timesCooked, 0)

        context.insert(CookingLogEntry(rating: 5, recipe: recipe))
        context.insert(CookingLogEntry(rating: 3, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.timesCooked, 2)
    }
}
