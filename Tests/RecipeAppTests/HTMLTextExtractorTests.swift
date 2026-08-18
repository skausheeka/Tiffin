import XCTest
@testable import RecipeApp

final class HTMLTextExtractorTests: XCTestCase {

    func test_plainText_stripsTags() {
        let html = "<p>Mix <b>flour</b> and <i>sugar</i>.</p>"

        XCTAssertEqual(HTMLTextExtractor.plainText(from: html), "Mix flour and sugar .")
    }

    func test_plainText_stripsScriptAndStyleBlocks() {
        let html = "<style>.a { color: red; }</style><p>Real content.</p><script>console.log('x')</script>"

        let result = HTMLTextExtractor.plainText(from: html)

        XCTAssertTrue(result.contains("Real content."))
        XCTAssertFalse(result.contains("color: red"))
        XCTAssertFalse(result.contains("console.log"))
    }

    func test_plainText_decodesHTMLEntities() {
        let html = "<p>Salt &amp; pepper &mdash; to taste &quot;a lot&quot;</p>".replacingOccurrences(of: "&mdash;", with: "")

        let result = HTMLTextExtractor.plainText(from: html)

        XCTAssertTrue(result.contains("Salt & pepper"))
        XCTAssertTrue(result.contains("\"a lot\""))
    }

    func test_plainText_collapsesWhitespace() {
        let html = "<p>Line one.</p>\n\n\n<p>   Line   two.   </p>"

        let result = HTMLTextExtractor.plainText(from: html)

        XCTAssertFalse(result.contains("   "))
        XCTAssertTrue(result.contains("Line one. Line two."))
    }

    func test_plainText_capsLengthAtMaximum() {
        let html = "<p>" + String(repeating: "a", count: 20_000) + "</p>"

        let result = HTMLTextExtractor.plainText(from: html)

        XCTAssertLessThanOrEqual(result.count, 12_000)
    }
}
