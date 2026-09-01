import XCTest
@testable import RecipeApp

final class RecipeCourseTests: XCTestCase {
    func test_hasExactlySixCourses() {
        XCTAssertEqual(RecipeCourse.allCases.count, 6)
    }

    func test_rawValues_areStableForPersistence() {
        // Recipe stores `course` as a raw String — changing these breaks existing saved recipes.
        XCTAssertEqual(RecipeCourse.breakfast.rawValue, "Breakfast")
        XCTAssertEqual(RecipeCourse.appetizer.rawValue, "Appetizer")
        XCTAssertEqual(RecipeCourse.entree.rawValue, "Entree")
        XCTAssertEqual(RecipeCourse.side.rawValue, "Side")
        XCTAssertEqual(RecipeCourse.snack.rawValue, "Snack")
        XCTAssertEqual(RecipeCourse.dessert.rawValue, "Dessert")
    }

    func test_id_matchesRawValue() {
        for course in RecipeCourse.allCases {
            XCTAssertEqual(course.id, course.rawValue)
        }
    }
}
