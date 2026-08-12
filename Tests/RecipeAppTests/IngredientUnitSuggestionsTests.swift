import XCTest
@testable import RecipeApp

final class IngredientUnitSuggestionsTests: XCTestCase {

    // MARK: - suggestedUnit

    func test_exactMatch_returnsMappedUnit() {
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "chicken"), "lb")
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "garlic"), "clove")
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "saffron"), "pinch")
    }

    func test_bulkStaples_useWeightNotVolume() {
        // These were specifically corrected from oz to lb — regression guard for that fix.
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "pasta"), "lb")
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "rice"), "lb")
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "spaghetti"), "lb")
    }

    func test_match_isCaseInsensitive() {
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "CHICKEN"), "lb")
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "ChIcKeN"), "lb")
    }

    func test_match_trimsWhitespace() {
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "  rice  "), "lb")
    }

    func test_substringMatch_prefersLongestKey() {
        // Contains both "chicken" (-> lb) and the more specific "chicken breast" (-> lb);
        // also exercises picking a longer, more specific key over a shorter contained one.
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "2 leftover chicken breast pieces"), "lb")
        XCTAssertEqual(IngredientUnitSuggestions.suggestedUnit(for: "farmers market tomatoes"), "whole")
    }

    func test_noMatch_returnsNil() {
        XCTAssertNil(IngredientUnitSuggestions.suggestedUnit(for: "unobtainium"))
    }

    func test_emptyOrWhitespaceOnly_returnsNil() {
        XCTAssertNil(IngredientUnitSuggestions.suggestedUnit(for: ""))
        XCTAssertNil(IngredientUnitSuggestions.suggestedUnit(for: "   "))
    }

    // MARK: - allUnits

    func test_allUnits_hasNoDuplicates() {
        let units = IngredientUnitSuggestions.allUnits
        XCTAssertEqual(units.count, Set(units).count)
    }

    func test_allUnits_isNotEmpty() {
        XCTAssertFalse(IngredientUnitSuggestions.allUnits.isEmpty)
    }

    func test_allUnits_putsCommonUnitsFirst() {
        let units = IngredientUnitSuggestions.allUnits
        guard let cupIndex = units.firstIndex(of: "cup"),
              let loafIndex = units.firstIndex(of: "loaf") else {
            return XCTFail("expected both 'cup' and 'loaf' to be present")
        }
        XCTAssertLessThan(cupIndex, loafIndex, "common units like 'cup' should sort before rarer ones like 'loaf'")
    }
}
