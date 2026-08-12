import XCTest
@testable import RecipeApp

final class RecipeRankingTests: XCTestCase {
    func test_excludesUnratedRecipes() {
        let rated = Recipe(title: "Rated", rating: 4)
        let unrated = Recipe(title: "Unrated")

        let ranked = Recipe.ranked([rated, unrated])

        XCTAssertEqual(ranked, [rated])
    }

    func test_sortsByRatingDescending() {
        let three = Recipe(title: "Three Stars", rating: 3)
        let five = Recipe(title: "Five Stars", rating: 5)
        let one = Recipe(title: "One Star", rating: 1)

        let ranked = Recipe.ranked([three, five, one])

        XCTAssertEqual(ranked, [five, three, one])
    }

    func test_tiesBrokenByTimesCookedDescending() {
        let cookedOnce = Recipe(title: "Cooked Once", rating: 5, timesCooked: 1)
        let cookedOften = Recipe(title: "Cooked Often", rating: 5, timesCooked: 12)
        let cookedTwice = Recipe(title: "Cooked Twice", rating: 5, timesCooked: 2)

        let ranked = Recipe.ranked([cookedOnce, cookedOften, cookedTwice])

        XCTAssertEqual(ranked, [cookedOften, cookedTwice, cookedOnce])
    }

    func test_ratingOutranksTimesCooked() {
        // A lower-rated recipe cooked constantly should still lose to a higher rating.
        let highRatingLowCooks = Recipe(title: "High Rating", rating: 5, timesCooked: 0)
        let lowRatingHighCooks = Recipe(title: "Low Rating", rating: 2, timesCooked: 50)

        let ranked = Recipe.ranked([lowRatingHighCooks, highRatingLowCooks])

        XCTAssertEqual(ranked, [highRatingLowCooks, lowRatingHighCooks])
    }

    func test_emptyInput_producesEmptyOutput() {
        XCTAssertEqual(Recipe.ranked([]), [])
    }
}
