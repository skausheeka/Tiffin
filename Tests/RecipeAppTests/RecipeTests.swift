import XCTest
@testable import RecipeApp

final class RecipeTests: XCTestCase {
    func test_init_appliesDefaults() {
        let recipe = Recipe(title: "Rasam")

        XCTAssertEqual(recipe.title, "Rasam")
        XCTAssertEqual(recipe.ingredients, [])
        XCTAssertEqual(recipe.instructionSteps, [])
        XCTAssertEqual(recipe.tags, [])
        XCTAssertEqual(recipe.photoFilenames, [])
        XCTAssertNil(recipe.prepTimeMinutes)
        XCTAssertNil(recipe.cookTimeMinutes)
        XCTAssertNil(recipe.servings)
        XCTAssertNil(recipe.sourceURL)
        XCTAssertNil(recipe.courseValue)
        XCTAssertNil(recipe.rating)
        XCTAssertNil(recipe.note)
        XCTAssertEqual(recipe.timesCooked, 0)
    }

    func test_courseValue_roundTripsThroughRawStorage() {
        let recipe = Recipe(title: "Gulab Jamun", course: .dessert)

        XCTAssertEqual(recipe.course, "Dessert")
        XCTAssertEqual(recipe.courseValue, .dessert)
    }

    func test_courseValue_isNilForUnrecognizedStoredString() {
        let recipe = Recipe(title: "Mystery Dish")
        recipe.course = "Not A Real Course"

        XCTAssertNil(recipe.courseValue)
    }

    func test_coverPhotoFilename_isFirstPhoto() {
        let recipe = Recipe(title: "Biryani", photoFilenames: ["a.jpg", "b.jpg"])

        XCTAssertEqual(recipe.coverPhotoFilename, "a.jpg")
    }

    func test_coverPhotoFilename_isNilWithNoPhotos() {
        let recipe = Recipe(title: "Biryani")

        XCTAssertNil(recipe.coverPhotoFilename)
    }
}
