import Foundation

enum ClaudeExtractionError: Error, LocalizedError {
    case missingAPIKey
    case network(Error)
    case httpError(status: Int, message: String?)
    case refusal
    case invalidResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "No Anthropic API key configured. Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig, add your key, then rebuild."
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let status, let message):
            return "Claude API error (\(status)): \(message ?? "unknown error")"
        case .refusal:
            return "Claude declined to process this recipe."
        case .invalidResponse:
            return "Couldn't read a response from Claude."
        case .decodingFailed:
            return "Couldn't parse the recipe Claude returned."
        }
    }
}

private struct LLMIngredient: Decodable {
    var amount: Double?
    var unit: String?
    var name: String
}

private struct LLMRecipeExtractionResponse: Decodable {
    var title: String
    var ingredients: [LLMIngredient]
    var prepSteps: [String]?
    var steps: [String]
    var course: String?
    var prepTimeMinutes: Int?
    var cookTimeMinutes: Int?
    var servings: Int?
    var tags: [String]?
}

private struct MessagesAPIResponse: Decodable {
    struct ContentBlock: Decodable {
        var type: String
        var text: String?
    }
    var content: [ContentBlock]
    var stopReason: String?

    enum CodingKeys: String, CodingKey {
        case content
        case stopReason = "stop_reason"
    }
}

/// Sends raw or scraped-page recipe text (or a photo of a recipe) to Claude for structured
/// extraction — the fallback path used when the free `RecipeJSONLDParser` path isn't
/// available. No official Anthropic Swift SDK exists, so this speaks the Messages API
/// directly over `URLSession`.
enum ClaudeRecipeExtractionService {
    private static let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let model = "claude-haiku-4-5"
    private static let apiVersion = "2023-06-01"

    private static let systemPrompt = """
    You extract structured recipe data from raw text — either scraped webpage content, \
    directly pasted recipe text, or a transcription of a photographed recipe (which may be \
    handwritten). If a field can't be confidently determined, return null (or an empty array) \
    rather than guessing. For ingredients, split each line into amount (a number, null if vague \
    like "to taste"), unit (a short standard unit, null if unitless e.g. "2 eggs"), and name \
    (keep useful qualifiers like "softened" or "diced" in the name). Split the method into two \
    ordered lists, with numbering or bullets stripped from each step: prepSteps for mise en \
    place done before active cooking starts (washing, chopping, marinating, measuring, mixing \
    dry ingredients, preheating), and steps for everything from the heat going on to plating. \
    If the recipe doesn't clearly separate prep from cooking, leave prepSteps empty and put \
    every step in steps — don't force a split that isn't there. For course, choose the single \
    best match from exactly Breakfast, Appetizer, Entree, Side, Snack, Dessert, or null if none \
    clearly fits. For tags, \
    put a guessed cuisine first if reasonably inferable (e.g. "Italian"), followed by up to 4 \
    other short descriptive tags. Times are whole minutes; if the source gives a range, use the \
    lower bound.
    """

    private static let responseSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "title": ["type": "string"],
            "ingredients": [
                "type": "array",
                "items": [
                    "type": "object",
                    "properties": [
                        "amount": ["type": ["number", "null"]],
                        "unit": ["type": ["string", "null"]],
                        "name": ["type": "string"],
                    ],
                    "required": ["name"],
                ],
            ],
            "prepSteps": ["type": "array", "items": ["type": "string"]],
            "steps": ["type": "array", "items": ["type": "string"]],
            "course": ["type": ["string", "null"], "enum": ["Breakfast", "Appetizer", "Entree", "Side", "Snack", "Dessert", NSNull()]],
            "prepTimeMinutes": ["type": ["integer", "null"]],
            "cookTimeMinutes": ["type": ["integer", "null"]],
            "servings": ["type": ["integer", "null"]],
            "tags": ["type": "array", "items": ["type": "string"]],
        ],
        "required": ["title", "ingredients", "steps"],
    ]

    static func apiKey() -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String else {
            return nil
        }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$("), trimmed != "REPLACE_ME" else {
            return nil
        }
        return trimmed
    }

    static func extractDraft(from text: String) async throws -> ParsedRecipeDraft {
        let content: [[String: Any]] = [
            ["type": "text", "text": "Extract the recipe from the following text:\n\n---\n\(text)"],
        ]
        let data = try await performRequest(content: content)
        return try parseExtractionResponse(data)
    }

    static func extractDraft(fromImageData imageData: Data, mediaType: String) async throws -> ParsedRecipeDraft {
        let content: [[String: Any]] = [
            [
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": mediaType,
                    "data": imageData.base64EncodedString(),
                ],
            ],
            [
                "type": "text",
                "text": "Extract the recipe from this photo, which may be a handwritten recipe card. Transcribe it as accurately as you can even if the handwriting is imperfect.",
            ],
        ]
        let data = try await performRequest(content: content)
        return try parseExtractionResponse(data)
    }

    /// Decodes the Messages API envelope and its structured-output JSON into a draft.
    /// Pure and fixture-testable — no network involved.
    static func parseExtractionResponse(_ data: Data) throws -> ParsedRecipeDraft {
        guard let envelope = try? JSONDecoder().decode(MessagesAPIResponse.self, from: data) else {
            throw ClaudeExtractionError.decodingFailed
        }
        if envelope.stopReason == "refusal" {
            throw ClaudeExtractionError.refusal
        }
        guard let jsonText = envelope.content.first(where: { $0.type == "text" })?.text,
              let jsonData = jsonText.data(using: .utf8) else {
            throw ClaudeExtractionError.invalidResponse
        }
        guard let parsed = try? JSONDecoder().decode(LLMRecipeExtractionResponse.self, from: jsonData) else {
            throw ClaudeExtractionError.decodingFailed
        }

        let ingredients = Recipe.cleanIngredients(parsed.ingredients.map {
            IngredientEntry(name: $0.name, amount: $0.amount, unit: $0.unit ?? "")
        })
        let prepSteps = Recipe.cleanSteps(parsed.prepSteps ?? [])
        let steps = Recipe.cleanSteps(parsed.steps)
        let course = parsed.course.flatMap { courseString in
            RecipeCourse.allCases.first { $0.rawValue.caseInsensitiveCompare(courseString) == .orderedSame }
        }
        let tags = (parsed.tags ?? []).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }

        return ParsedRecipeDraft(
            title: parsed.title.trimmingCharacters(in: .whitespaces),
            ingredients: ingredients,
            prepSteps: prepSteps,
            steps: steps,
            course: course,
            prepTimeMinutes: parsed.prepTimeMinutes,
            cookTimeMinutes: parsed.cookTimeMinutes,
            servings: parsed.servings,
            tags: tags,
            sourceURL: nil
        )
    }

    private static func performRequest(content: Any) async throws -> Data {
        guard let apiKey = apiKey() else {
            throw ClaudeExtractionError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody(content: content))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ClaudeExtractionError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClaudeExtractionError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let errorDict = json?["error"] as? [String: Any]
            let message = errorDict?["message"] as? String
            throw ClaudeExtractionError.httpError(status: httpResponse.statusCode, message: message)
        }
        return data
    }

    private static func requestBody(content: Any) -> [String: Any] {
        [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": content],
            ],
            "output_config": [
                "format": [
                    "type": "json_schema",
                    "schema": responseSchema,
                ],
            ],
        ]
    }
}
