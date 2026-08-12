import XCTest
@testable import RecipeApp

final class RecipeCourseTests: XCTestCase {
    func test_hasExactlyThreeCourses() {
        XCTAssertEqual(RecipeCourse.allCases.count, 3)
    }

    func test_rawValues_areStableForPersistence() {
        // Recipe stores `course` as a raw String — changing these breaks existing saved recipes.
        XCTAssertEqual(RecipeCourse.appetizer.rawValue, "Appetizer")
        XCTAssertEqual(RecipeCourse.entree.rawValue, "Entree")
        XCTAssertEqual(RecipeCourse.dessert.rawValue, "Dessert")
    }

    func test_id_matchesRawValue() {
        for course in RecipeCourse.allCases {
            XCTAssertEqual(course.id, course.rawValue)
        }
    }
}
