import XCTest
import SwiftData
@testable import RecipeApp

final class RecipeRankingTests: XCTestCase {
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

    /// Logs one cooking entry per rating given, in order, all dated `.now`.
    private func log(_ ratings: [Int], for recipe: Recipe) {
        for rating in ratings {
            let entry = CookingLogEntry(rating: rating, recipe: recipe)
            context.insert(entry)
        }
    }

    func test_excludesUnratedRecipes() throws {
        let rated = Recipe(title: "Rated")
        let unrated = Recipe(title: "Unrated")
        context.insert(rated)
        context.insert(unrated)
        log([4], for: rated)
        try context.save()

        let ranked = Recipe.ranked([rated, unrated])

        XCTAssertEqual(ranked, [rated])
    }

    func test_sortsByAverageRatingDescending() throws {
        let three = Recipe(title: "Three Stars")
        let five = Recipe(title: "Five Stars")
        let one = Recipe(title: "One Star")
        context.insert(three)
        context.insert(five)
        context.insert(one)
        log([3], for: three)
        log([5], for: five)
        log([1], for: one)
        try context.save()

        let ranked = Recipe.ranked([three, five, one])

        XCTAssertEqual(ranked, [five, three, one])
    }

    func test_averageRating_isMeanOfAllLoggedCooks() throws {
        let recipe = Recipe(title: "Dal")
        context.insert(recipe)
        log([5, 4, 3], for: recipe) // average 4.0
        try context.save()

        XCTAssertEqual(recipe.averageRating, 4.0)
    }

    func test_tiesBrokenByTimesCookedDescending() throws {
        let cookedOnce = Recipe(title: "Cooked Once")
        let cookedOften = Recipe(title: "Cooked Often")
        let cookedTwice = Recipe(title: "Cooked Twice")
        context.insert(cookedOnce)
        context.insert(cookedOften)
        context.insert(cookedTwice)
        log([5], for: cookedOnce)
        log(Array(repeating: 5, count: 12), for: cookedOften)
        log([5, 5], for: cookedTwice)
        try context.save()

        let ranked = Recipe.ranked([cookedOnce, cookedOften, cookedTwice])

        XCTAssertEqual(ranked, [cookedOften, cookedTwice, cookedOnce])
    }

    func test_averageRatingOutranksTimesCooked() throws {
        // A lower-rated recipe cooked constantly should still lose to a higher average.
        let highRatingLowCooks = Recipe(title: "High Rating")
        let lowRatingHighCooks = Recipe(title: "Low Rating")
        context.insert(highRatingLowCooks)
        context.insert(lowRatingHighCooks)
        log([5], for: highRatingLowCooks)
        log(Array(repeating: 2, count: 50), for: lowRatingHighCooks)
        try context.save()

        let ranked = Recipe.ranked([lowRatingHighCooks, highRatingLowCooks])

        XCTAssertEqual(ranked, [highRatingLowCooks, lowRatingHighCooks])
    }

    func test_emptyInput_producesEmptyOutput() {
        XCTAssertEqual(Recipe.ranked([]), [])
    }
}
