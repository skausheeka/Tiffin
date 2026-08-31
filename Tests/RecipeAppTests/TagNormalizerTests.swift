import XCTest
@testable import RecipeApp

final class TagNormalizerTests: XCTestCase {
    // MARK: - titleCased

    func test_titleCased_lowercaseInput() {
        XCTAssertEqual(TagNormalizer.titleCased("indian"), "Indian")
    }

    func test_titleCased_uppercaseInput() {
        XCTAssertEqual(TagNormalizer.titleCased("INDIAN"), "Indian")
    }

    func test_titleCased_mixedCaseInput() {
        XCTAssertEqual(TagNormalizer.titleCased("InDiAn"), "Indian")
    }

    func test_titleCased_multipleWords() {
        XCTAssertEqual(TagNormalizer.titleCased("south indian"), "South Indian")
    }

    func test_titleCased_alreadyCorrect_isUnchanged() {
        XCTAssertEqual(TagNormalizer.titleCased("Indian"), "Indian")
    }

    func test_titleCased_emptyString() {
        XCTAssertEqual(TagNormalizer.titleCased(""), "")
    }

    // MARK: - levenshteinDistance

    func test_levenshteinDistance_identicalStrings_isZero() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("indian", "indian"), 0)
    }

    func test_levenshteinDistance_isCaseInsensitive() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("Indian", "indian"), 0)
    }

    func test_levenshteinDistance_singleInsertion() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("cat", "cats"), 1)
    }

    func test_levenshteinDistance_singleSubstitution() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("cat", "hat"), 1)
    }

    func test_levenshteinDistance_completelyDifferentShortStrings() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("cat", "dog"), 3)
    }

    func test_levenshteinDistance_emptyStrings() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("", ""), 0)
        XCTAssertEqual(TagNormalizer.levenshteinDistance("cat", ""), 3)
    }

    func test_levenshteinDistance_realisticTypo() {
        XCTAssertEqual(TagNormalizer.levenshteinDistance("Indian", "Indiyan"), 1)
    }

    // MARK: - possibleTypo

    func test_possibleTypo_identicalIgnoringCase_isFalse() {
        XCTAssertFalse(TagNormalizer.possibleTypo("Indian", "indian"))
    }

    func test_possibleTypo_closeMisspelling_isTrue() {
        XCTAssertTrue(TagNormalizer.possibleTypo("Indian", "Indiyan"))
    }

    func test_possibleTypo_singleCharDifference_isTrue() {
        XCTAssertTrue(TagNormalizer.possibleTypo("cat", "hat"))
    }

    func test_possibleTypo_tooDifferentForShortStrings_isFalse() {
        // "cat" -> "hats" is 2 edits, above the length-scaled threshold for 3-char words.
        XCTAssertFalse(TagNormalizer.possibleTypo("cat", "hats"))
    }

    func test_possibleTypo_unrelatedWords_isFalse() {
        XCTAssertFalse(TagNormalizer.possibleTypo("Indian", "Mexican"))
    }
}
