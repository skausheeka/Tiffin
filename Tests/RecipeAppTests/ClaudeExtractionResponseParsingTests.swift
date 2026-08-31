import XCTest
@testable import RecipeApp

final class ClaudeExtractionResponseParsingTests: XCTestCase {

    private func envelope(schemaJSON: String, stopReason: String = "end_turn") -> Data {
        let escaped = schemaJSON
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
        let json = """
        {
            "id": "msg_test",
            "content": [{"type": "text", "text": "\(escaped)"}],
            "stop_reason": "\(stopReason)"
        }
        """
        return Data(json.utf8)
    }

    func test_parseExtractionResponse_wellFormedSchema() throws {
        let schema = """
        {
            "title": "Weeknight Pasta",
            "ingredients": [{"amount": 8, "unit": "oz", "name": "spaghetti"}],
            "prepSteps": ["Measure out the spaghetti."],
            "steps": ["Boil water.", "Cook pasta."],
            "course": "Entree",
            "prepTimeMinutes": 10,
            "cookTimeMinutes": 15,
            "servings": 4,
            "tags": ["Italian", "quick"]
        }
        """

        let draft = try ClaudeRecipeExtractionService.parseExtractionResponse(envelope(schemaJSON: schema))

        XCTAssertEqual(draft.title, "Weeknight Pasta")
        XCTAssertEqual(draft.ingredients.count, 1)
        XCTAssertEqual(draft.ingredients.first?.name, "spaghetti")
        XCTAssertEqual(draft.prepSteps, ["Measure out the spaghetti."])
        XCTAssertEqual(draft.steps, ["Boil water.", "Cook pasta."])
        XCTAssertEqual(draft.course, .entree)
        XCTAssertEqual(draft.prepTimeMinutes, 10)
        XCTAssertEqual(draft.cookTimeMinutes, 15)
        XCTAssertEqual(draft.servings, 4)
        XCTAssertEqual(draft.tags, ["Italian", "quick"])
    }

    func test_parseExtractionResponse_nullFields_mapToNil() throws {
        let schema = """
        {
            "title": "Minimal",
            "ingredients": [{"amount": null, "unit": null, "name": "salt"}],
            "steps": [],
            "course": null,
            "prepTimeMinutes": null,
            "cookTimeMinutes": null,
            "servings": null,
            "tags": []
        }
        """

        let draft = try ClaudeRecipeExtractionService.parseExtractionResponse(envelope(schemaJSON: schema))

        XCTAssertNil(draft.course)
        XCTAssertNil(draft.prepTimeMinutes)
        XCTAssertEqual(draft.ingredients.first?.amount, nil)
        XCTAssertEqual(draft.ingredients.first?.unit, "")
    }

    func test_parseExtractionResponse_unrecognizedCourseString_producesNilCourse() throws {
        let schema = """
        {
            "title": "Weird Course",
            "ingredients": [{"name": "flour"}],
            "steps": ["Mix."],
            "course": "Brunch",
            "tags": []
        }
        """

        let draft = try ClaudeRecipeExtractionService.parseExtractionResponse(envelope(schemaJSON: schema))

        XCTAssertNil(draft.course)
    }

    func test_parseExtractionResponse_courseMatchIsCaseInsensitive() throws {
        let schema = """
        {"title": "Case Test", "ingredients": [{"name": "flour"}], "steps": ["Mix."], "course": "dessert", "tags": []}
        """

        let draft = try ClaudeRecipeExtractionService.parseExtractionResponse(envelope(schemaJSON: schema))

        XCTAssertEqual(draft.course, .dessert)
    }

    func test_parseExtractionResponse_malformedSchemaJSON_throwsDecodingFailed() {
        let ns = "{not valid json"
        let data = envelope(schemaJSON: ns)

        XCTAssertThrowsError(try ClaudeRecipeExtractionService.parseExtractionResponse(data)) { error in
            XCTAssertTrue(error is ClaudeExtractionError)
        }
    }

    func test_parseExtractionResponse_refusalStopReason_throwsRefusal() {
        let schema = "{}"
        let data = envelope(schemaJSON: schema, stopReason: "refusal")

        XCTAssertThrowsError(try ClaudeRecipeExtractionService.parseExtractionResponse(data)) { error in
            guard case ClaudeExtractionError.refusal = error else {
                return XCTFail("Expected .refusal, got \(error)")
            }
        }
    }

    func test_parseExtractionResponse_malformedEnvelope_throwsDecodingFailed() {
        let data = Data("not even json".utf8)

        XCTAssertThrowsError(try ClaudeRecipeExtractionService.parseExtractionResponse(data)) { error in
            guard case ClaudeExtractionError.decodingFailed = error else {
                return XCTFail("Expected .decodingFailed, got \(error)")
            }
        }
    }

    func test_parseExtractionResponse_cleansIngredientsAndStepsLikeManualEntry() throws {
        let schema = """
        {
            "title": "  Trim Test  ",
            "ingredients": [{"name": "  flour  ", "unit": "  cup  "}, {"name": "   "}],
            "steps": ["  Step one.  ", ""],
            "tags": ["  Italian  ", ""]
        }
        """

        let draft = try ClaudeRecipeExtractionService.parseExtractionResponse(envelope(schemaJSON: schema))

        XCTAssertEqual(draft.title, "Trim Test")
        XCTAssertEqual(draft.ingredients.count, 1)
        XCTAssertEqual(draft.ingredients.first?.name, "flour")
        XCTAssertEqual(draft.ingredients.first?.unit, "cup")
        XCTAssertEqual(draft.steps, ["Step one."])
        XCTAssertEqual(draft.tags, ["Italian"])
    }
}
