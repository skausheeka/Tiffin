import XCTest
@testable import RecipeApp

final class IngredientLineParserTests: XCTestCase {

    func test_parse_integerAmountWithUnit() {
        let entry = IngredientLineParser.parse("2 cups all-purpose flour")

        XCTAssertEqual(entry.amount, 2)
        XCTAssertEqual(entry.unit, "cups")
        XCTAssertEqual(entry.name, "all-purpose flour")
    }

    func test_parse_simpleFraction() {
        let entry = IngredientLineParser.parse("1/2 tsp salt")

        XCTAssertEqual(entry.amount, 0.5)
        XCTAssertEqual(entry.unit, "tsp")
        XCTAssertEqual(entry.name, "salt")
    }

    func test_parse_mixedNumber() {
        let entry = IngredientLineParser.parse("1 1/2 cups sugar")

        XCTAssertEqual(entry.amount, 1.5)
        XCTAssertEqual(entry.unit, "cups")
        XCTAssertEqual(entry.name, "sugar")
    }

    func test_parse_decimalAmount() {
        let entry = IngredientLineParser.parse("1.5 lbs ground beef")

        XCTAssertEqual(entry.amount, 1.5)
        XCTAssertEqual(entry.unit, "lbs")
        XCTAssertEqual(entry.name, "ground beef")
    }

    func test_parse_unicodeVulgarFractionAlone() {
        let entry = IngredientLineParser.parse("½ cup butter")

        XCTAssertEqual(entry.amount, 0.5)
        XCTAssertEqual(entry.unit, "cup")
        XCTAssertEqual(entry.name, "butter")
    }

    func test_parse_unicodeVulgarFractionAfterInteger() {
        let entry = IngredientLineParser.parse("1½ cups flour")

        XCTAssertEqual(entry.amount, 1.5)
        XCTAssertEqual(entry.unit, "cups")
        XCTAssertEqual(entry.name, "flour")
    }

    func test_parse_rangeWithHyphen_usesFirstNumber() {
        let entry = IngredientLineParser.parse("3-4 cloves garlic, minced")

        XCTAssertEqual(entry.amount, 3)
        XCTAssertEqual(entry.unit, "cloves")
        XCTAssertEqual(entry.name, "garlic, minced")
    }

    func test_parse_rangeWithTo_usesFirstNumber() {
        let entry = IngredientLineParser.parse("3 to 4 large eggs")

        XCTAssertEqual(entry.amount, 3)
        XCTAssertEqual(entry.name, "large eggs")
    }

    func test_parse_unitlessQuantifiedIngredient() {
        let entry = IngredientLineParser.parse("2 large eggs")

        XCTAssertEqual(entry.amount, 2)
        XCTAssertEqual(entry.unit, "")
        XCTAssertEqual(entry.name, "large eggs")
    }

    func test_parse_noAmount_wholeLineBecomesName() {
        let entry = IngredientLineParser.parse("Kosher salt, to taste")

        XCTAssertNil(entry.amount)
        XCTAssertEqual(entry.unit, "")
        XCTAssertEqual(entry.name, "Kosher salt, to taste")
    }

    func test_parse_stripsLeadingBulletMarker() {
        let entry = IngredientLineParser.parse("- 2 tbsp olive oil")

        XCTAssertEqual(entry.amount, 2)
        XCTAssertEqual(entry.unit, "tbsp")
        XCTAssertEqual(entry.name, "olive oil")
    }

    func test_parse_emptyLine_producesEmptyName() {
        let entry = IngredientLineParser.parse("   ")

        XCTAssertNil(entry.amount)
        XCTAssertEqual(entry.name, "")
    }
}
