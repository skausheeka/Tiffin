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
        let entry = CookingLogEntry(rating: 4, timeMinutes: 30, recipe: recipe)

        XCTAssertEqual(entry.rating, 4)
        XCTAssertNil(entry.note)
        XCTAssertTrue(entry.recipe === recipe)
    }

    func test_init_acceptsExplicitTimeMinutes() {
        let recipe = Recipe(title: "Dal")
        let entry = CookingLogEntry(rating: 4, timeMinutes: 42, recipe: recipe)

        XCTAssertEqual(entry.timeMinutes, 42)
    }

    func test_init_acceptsExplicitDateAndNote() {
        let recipe = Recipe(title: "Dal")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = CookingLogEntry(date: date, rating: 3, timeMinutes: 20, note: "too salty", recipe: recipe)

        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.note, "too salty")
    }

    func test_init_defaultsPhotoFilenameToNil() {
        let recipe = Recipe(title: "Dal")
        let entry = CookingLogEntry(rating: 4, timeMinutes: 30, recipe: recipe)

        XCTAssertNil(entry.photoFilename)
    }

    func test_init_acceptsExplicitPhotoFilename() {
        let recipe = Recipe(title: "Dal")
        let entry = CookingLogEntry(rating: 4, timeMinutes: 30, photoFilename: "abc.jpg", recipe: recipe)

        XCTAssertEqual(entry.photoFilename, "abc.jpg")
    }

    func test_deletingRecipe_cascadesToItsCookingLogEntries() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = CookingLogEntry(rating: 5, timeMinutes: 30, recipe: recipe)
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
        let entry = CookingLogEntry(rating: 5, timeMinutes: 30, recipe: recipe)
        context.insert(entry)
        try context.save()

        context.delete(entry)
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Recipe>()), 1)
    }

    func test_recipeCookingLogEntries_reflectsInverseRelationship() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        let entry = CookingLogEntry(rating: 5, timeMinutes: 30, recipe: recipe)
        context.insert(entry)
        try context.save()

        XCTAssertEqual(recipe.cookingLogEntries?.count, 1)
        XCTAssertTrue(recipe.cookingLogEntries?.first === entry)
    }

    func test_averageRating_isNilWithNoEntries() {
        let recipe = Recipe(title: "Dal")

        XCTAssertNil(recipe.averageRating)
    }

    func test_averageRating_matchesSingleEntry() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        context.insert(CookingLogEntry(rating: 4, timeMinutes: 30, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.averageRating, 4.0)
    }

    func test_averageRating_isMeanAcrossMultipleEntries() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        context.insert(CookingLogEntry(rating: 5, timeMinutes: 30, recipe: recipe))
        context.insert(CookingLogEntry(rating: 4, timeMinutes: 25, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.averageRating, 4.5)
    }

    func test_timesCooked_reflectsEntryCount() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        XCTAssertEqual(recipe.timesCooked, 0)

        context.insert(CookingLogEntry(rating: 5, timeMinutes: 30, recipe: recipe))
        context.insert(CookingLogEntry(rating: 3, timeMinutes: 40, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.timesCooked, 2)
    }

    // MARK: - Recipe.lastLoggedTimeMinutes / displayedTimeMinutes

    func test_lastLoggedTimeMinutes_isNilWithNoEntries() {
        let recipe = Recipe(title: "Dal")

        XCTAssertNil(recipe.lastLoggedTimeMinutes)
    }

    func test_lastLoggedTimeMinutes_treatsZeroAsNoRealValue() throws {
        // A 0 only ever means an entry logged before `timeMinutes` existed — SwiftData
        // defaults new columns to 0 for pre-existing rows on migration, not a real cook.
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        context.insert(CookingLogEntry(rating: 4, timeMinutes: 0, recipe: recipe))
        try context.save()

        XCTAssertNil(recipe.lastLoggedTimeMinutes)
    }

    func test_lastLoggedTimeMinutes_matchesMostRecentEntry() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        context.insert(CookingLogEntry(
            date: Date(timeIntervalSince1970: 1_700_000_000),
            rating: 4,
            timeMinutes: 25,
            recipe: recipe
        ))
        context.insert(CookingLogEntry(
            date: Date(timeIntervalSince1970: 1_700_100_000),
            rating: 5,
            timeMinutes: 40,
            recipe: recipe
        ))
        try context.save()

        XCTAssertEqual(recipe.lastLoggedTimeMinutes, 40)
    }

    func test_displayedTimeMinutes_fallsBackToEstimateWhenNeverCooked() {
        let recipe = Recipe(title: "Dal", prepTimeMinutes: 10, cookTimeMinutes: 15)

        XCTAssertEqual(recipe.displayedTimeMinutes, 25)
    }

    func test_displayedTimeMinutes_prefersLastLoggedOverEstimate() throws {
        let recipe = Recipe(title: "Dal", prepTimeMinutes: 10, cookTimeMinutes: 15)
        context.insert(recipe)
        context.insert(CookingLogEntry(rating: 4, timeMinutes: 50, recipe: recipe))
        try context.save()

        XCTAssertEqual(recipe.displayedTimeMinutes, 50)
    }

    func test_displayedTimeMinutes_isNilWithNoEstimateAndNeverCooked() {
        let recipe = Recipe(title: "Dal")

        XCTAssertNil(recipe.displayedTimeMinutes)
    }
}
