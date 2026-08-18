import XCTest
@testable import RecipeApp

final class RecipeInputParsingTests: XCTestCase {

    // MARK: - cleanIngredients

    func test_cleanIngredients_trimsNameAndUnit() {
        let rows = [IngredientEntry(name: "  Rice  ", amount: 2, unit: "  cup  ")]

        let cleaned = Recipe.cleanIngredients(rows)

        XCTAssertEqual(cleaned.first?.name, "Rice")
        XCTAssertEqual(cleaned.first?.unit, "cup")
    }

    func test_cleanIngredients_dropsRowsWithBlankName() {
        let rows = [
            IngredientEntry(name: "Rice", unit: "cup"),
            IngredientEntry(name: "", unit: "tbsp"),
            IngredientEntry(name: "   ", unit: "tsp"),
        ]

        let cleaned = Recipe.cleanIngredients(rows)

        XCTAssertEqual(cleaned.count, 1)
        XCTAssertEqual(cleaned.first?.name, "Rice")
    }

    func test_cleanIngredients_keepsRowWithNameButNoUnit() {
        let rows = [IngredientEntry(name: "Salt", unit: "")]

        let cleaned = Recipe.cleanIngredients(rows)

        XCTAssertEqual(cleaned.count, 1)
        XCTAssertEqual(cleaned.first?.unit, "")
    }

    // MARK: - cleanSteps

    func test_cleanSteps_trimsAndDropsBlankSteps() {
        let steps = ["  Preheat oven  ", "", "   ", "Mix ingredients"]

        XCTAssertEqual(Recipe.cleanSteps(steps), ["Preheat oven", "Mix ingredients"])
    }

    func test_cleanSteps_emptyInput_producesEmptyOutput() {
        XCTAssertEqual(Recipe.cleanSteps([]), [])
    }
}
