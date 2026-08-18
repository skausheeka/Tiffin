import XCTest
@testable import RecipeApp

final class RecipeImporterClassifyTests: XCTestCase {

    func test_classify_plainHTTPSURL_isURL() {
        let result = RecipeImporter.classify("https://example.com/recipes/dal")

        guard case .url(let url) = result else {
            return XCTFail("Expected .url, got \(result)")
        }
        XCTAssertEqual(url.absoluteString, "https://example.com/recipes/dal")
    }

    func test_classify_httpURL_isURL() {
        let result = RecipeImporter.classify("http://example.com/recipe")

        guard case .url = result else {
            return XCTFail("Expected .url, got \(result)")
        }
    }

    func test_classify_whitespacePaddedURL_isURL() {
        let result = RecipeImporter.classify("   https://example.com/recipe   \n")

        guard case .url = result else {
            return XCTFail("Expected .url, got \(result)")
        }
    }

    func test_classify_multiLinePasteStartingWithURL_isRawText() {
        let input = "https://example.com/recipe\n2 cups flour\n1 tsp salt"

        let result = RecipeImporter.classify(input)

        guard case .rawText = result else {
            return XCTFail("Expected .rawText, got \(result)")
        }
    }

    func test_classify_plainRecipeText_isRawText() {
        let result = RecipeImporter.classify("2 cups flour\n1 tsp salt\nMix and bake.")

        guard case .rawText = result else {
            return XCTFail("Expected .rawText, got \(result)")
        }
    }

    func test_classify_nonHTTPScheme_isRawText() {
        let result = RecipeImporter.classify("ftp://example.com/recipe")

        guard case .rawText = result else {
            return XCTFail("Expected .rawText, got \(result)")
        }
    }

    func test_classify_emptyString_isRawText() {
        let result = RecipeImporter.classify("")

        guard case .rawText(let text) = result else {
            return XCTFail("Expected .rawText, got \(result)")
        }
        XCTAssertEqual(text, "")
    }

    func test_classify_bareWordNotAURL_isRawText() {
        let result = RecipeImporter.classify("Dal Recipe")

        guard case .rawText = result else {
            return XCTFail("Expected .rawText, got \(result)")
        }
    }
}
