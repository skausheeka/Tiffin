import Foundation

enum RecipeImportInput: Equatable {
    case url(URL)
    case rawText(String)
}

enum RecipeImportError: Error, LocalizedError {
    case emptyInput

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Paste a recipe URL or some recipe text first."
        }
    }
}

/// Orchestrates the two import paths: a URL tries the free JSON-LD parser first and falls
/// back to the LLM if the page has no usable structured data; raw pasted text and photos go
/// straight to the LLM.
enum RecipeImporter {
    /// Classifies raw pasted input as a URL only when the *entire* trimmed input is a single
    /// line that parses as an absolute http/https URL — a multi-line paste that happens to
    /// start with a URL-looking line is correctly treated as text, not misread as one.
    static func classify(_ rawInput: String) -> RecipeImportInput {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(where: { $0.isNewline }),
              let components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(), scheme == "http" || scheme == "https",
              let host = components.host, !host.isEmpty,
              let url = components.url else {
            return .rawText(trimmed)
        }
        return .url(url)
    }

    static func importRecipe(from rawInput: String) async throws -> ParsedRecipeDraft {
        let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RecipeImportError.emptyInput }

        switch classify(trimmed) {
        case .rawText(let text):
            return try await ClaudeRecipeExtractionService.extractDraft(from: text)
        case .url(let url):
            let html = try await RecipePageFetcher.fetchHTML(from: url)
            if var draft = RecipeJSONLDParser.extractRecipeDraft(fromHTML: html) {
                draft.sourceURL = url.absoluteString
                return draft
            }
            let pageText = HTMLTextExtractor.plainText(from: html)
            var draft = try await ClaudeRecipeExtractionService.extractDraft(from: pageText)
            draft.sourceURL = url.absoluteString
            return draft
        }
    }

    static func importRecipe(fromImageData imageData: Data, mediaType: String) async throws -> ParsedRecipeDraft {
        try await ClaudeRecipeExtractionService.extractDraft(fromImageData: imageData, mediaType: mediaType)
    }
}
