import XCTest
import SwiftData
@testable import RecipeApp

final class RecipeFilterTests: XCTestCase {
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

    // MARK: - TimeBucket

    func test_timeBucket_under30() {
        XCTAssertTrue(TimeBucket.under30.matches(totalMinutes: 20))
        XCTAssertFalse(TimeBucket.under30.matches(totalMinutes: 30))
    }

    func test_timeBucket_thirtyToSixty_isInclusiveOnBothEnds() {
        XCTAssertTrue(TimeBucket.thirtyToSixty.matches(totalMinutes: 30))
        XCTAssertTrue(TimeBucket.thirtyToSixty.matches(totalMinutes: 60))
        XCTAssertFalse(TimeBucket.thirtyToSixty.matches(totalMinutes: 29))
        XCTAssertFalse(TimeBucket.thirtyToSixty.matches(totalMinutes: 61))
    }

    func test_timeBucket_over60() {
        XCTAssertTrue(TimeBucket.over60.matches(totalMinutes: 61))
        XCTAssertFalse(TimeBucket.over60.matches(totalMinutes: 60))
    }

    // MARK: - CookedBucket

    func test_cookedBucket_never() {
        XCTAssertTrue(CookedBucket.never.matches(timesCooked: 0))
        XCTAssertFalse(CookedBucket.never.matches(timesCooked: 1))
    }

    func test_cookedBucket_oneOrTwo() {
        XCTAssertTrue(CookedBucket.oneOrTwo.matches(timesCooked: 1))
        XCTAssertTrue(CookedBucket.oneOrTwo.matches(timesCooked: 2))
        XCTAssertFalse(CookedBucket.oneOrTwo.matches(timesCooked: 3))
    }

    func test_cookedBucket_threePlus() {
        XCTAssertTrue(CookedBucket.threePlus.matches(timesCooked: 3))
        XCTAssertTrue(CookedBucket.threePlus.matches(timesCooked: 50))
        XCTAssertFalse(CookedBucket.threePlus.matches(timesCooked: 2))
    }

    // MARK: - RecipeFilter.matches — individual dimensions

    func test_defaultFilter_isInactiveAndMatchesEverything() {
        let filter = RecipeFilter()
        let recipe = Recipe(title: "Dal")

        XCTAssertFalse(filter.isActive)
        XCTAssertEqual(filter.activeCount, 0)
        XCTAssertTrue(filter.matches(recipe))
    }

    func test_cuisineFilter_matchesFirstTagOnly() {
        var filter = RecipeFilter()
        filter.cuisine = "Indian"

        let indian = Recipe(title: "Dal", tags: ["Indian", "dinner"])
        let italian = Recipe(title: "Pasta", tags: ["Italian"])
        let untagged = Recipe(title: "Mystery")

        XCTAssertTrue(filter.matches(indian))
        XCTAssertFalse(filter.matches(italian))
        XCTAssertFalse(filter.matches(untagged))
    }

    func test_courseFilter() {
        var filter = RecipeFilter()
        filter.course = .dessert

        XCTAssertTrue(filter.matches(Recipe(title: "Gulab Jamun", course: .dessert)))
        XCTAssertFalse(filter.matches(Recipe(title: "Dal", course: .entree)))
        XCTAssertFalse(filter.matches(Recipe(title: "No Course")))
    }

    func test_timeBucketFilter_excludesRecipesWithNoTimeSet() {
        var filter = RecipeFilter()
        filter.timeBucket = .under30

        let quick = Recipe(title: "Quick", prepTimeMinutes: 10, cookTimeMinutes: 15)
        let noTime = Recipe(title: "No Time")

        XCTAssertTrue(filter.matches(quick))
        XCTAssertFalse(filter.matches(noTime))
    }

    func test_cookedBucketFilter() throws {
        var filter = RecipeFilter()
        filter.cookedBucket = .threePlus

        let cookedOften = Recipe(title: "Often")
        let cookedNever = Recipe(title: "Never")
        context.insert(cookedOften)
        context.insert(cookedNever)
        for _ in 0..<3 {
            context.insert(CookingLogEntry(rating: 5, recipe: cookedOften))
        }
        try context.save()

        XCTAssertTrue(filter.matches(cookedOften))
        XCTAssertFalse(filter.matches(cookedNever))
    }

    // MARK: - RecipeFilter.matches — combined (AND, not OR)

    func test_combinedFilters_requireAllDimensionsToMatch() {
        var filter = RecipeFilter()
        filter.cuisine = "Indian"
        filter.course = .dessert

        let matchesBoth = Recipe(title: "Gulab Jamun", tags: ["Indian"], course: .dessert)
        let matchesOnlyCuisine = Recipe(title: "Dal", tags: ["Indian"], course: .entree)
        let matchesOnlyCourse = Recipe(title: "Tiramisu", tags: ["Italian"], course: .dessert)

        XCTAssertEqual(filter.activeCount, 2)
        XCTAssertTrue(filter.matches(matchesBoth))
        XCTAssertFalse(filter.matches(matchesOnlyCuisine))
        XCTAssertFalse(filter.matches(matchesOnlyCourse))
    }
}
