import XCTest
@testable import RecipeApp

final class IngredientEntryTests: XCTestCase {
    func test_init_appliesDefaults() {
        let entry = IngredientEntry()

        XCTAssertEqual(entry.name, "")
        XCTAssertNil(entry.amount)
        XCTAssertEqual(entry.unit, "")
    }

    func test_equality_isByValueNotJustID() {
        let id = UUID()
        let a = IngredientEntry(id: id, name: "Rice", amount: 2, unit: "cup")
        let b = IngredientEntry(id: id, name: "Rice", amount: 2, unit: "cup")
        let differentUnit = IngredientEntry(id: id, name: "Rice", amount: 2, unit: "lb")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, differentUnit)
    }
}
