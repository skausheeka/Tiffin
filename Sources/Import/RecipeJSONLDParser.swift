import Foundation

/// Parses schema.org `Recipe` structured data embedded in a page's
/// `<script type="application/ld+json">` blocks — the free, deterministic import path that
/// covers most real recipe sites (AllRecipes, NYT Cooking, Food Network, WordPress recipe
/// plugins) without needing an LLM call.
enum RecipeJSONLDParser {
    static func extractRecipeDraft(fromHTML html: String) -> ParsedRecipeDraft? {
        for block in jsonLDBlocks(in: html) {
            if let draft = parseJSONLD(block) {
                return draft
            }
        }
        return nil
    }

    /// Parses a single JSON-LD blob (already extracted from a `<script>` tag) into a draft.
    /// Pure and fixture-testable — no network involved.
    static func parseJSONLD(_ jsonString: String) -> ParsedRecipeDraft? {
        let decoded = decodeHTMLEntities(jsonString)
        guard let data = decoded.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        guard let recipeObject = findRecipeObject(in: root) else { return nil }
        return draft(from: recipeObject)
    }

    // MARK: - Locating the Recipe object

    private static func findRecipeObject(in json: Any) -> [String: Any]? {
        if let dict = json as? [String: Any] {
            if isRecipeType(dict["@type"]) {
                return dict
            }
            if let graph = dict["@graph"] as? [Any] {
                for item in graph {
                    if let found = findRecipeObject(in: item) {
                        return found
                    }
                }
            }
            return nil
        }
        if let array = json as? [Any] {
            for item in array {
                if let found = findRecipeObject(in: item) {
                    return found
                }
            }
        }
        return nil
    }

    private static func isRecipeType(_ value: Any?) -> Bool {
        if let type = value as? String {
            return type.caseInsensitiveCompare("Recipe") == .orderedSame
        }
        if let types = value as? [String] {
            return types.contains { $0.caseInsensitiveCompare("Recipe") == .orderedSame }
        }
        return false
    }

    // MARK: - Mapping to ParsedRecipeDraft

    private static func draft(from recipe: [String: Any]) -> ParsedRecipeDraft? {
        let title = stringValue(recipe["name"]) ?? ""
        let ingredientLines = stringArray(recipe["recipeIngredient"]) ?? stringArray(recipe["ingredients"]) ?? []
        let ingredients = ingredientLines.map(IngredientLineParser.parse)
        let flattenedInstructions = flattenInstructions(recipe["recipeInstructions"])

        guard !title.isEmpty, !ingredients.isEmpty else { return nil }

        let cuisine = stringValue(recipe["recipeCuisine"])
        let keywordTags = (stringValue(recipe["keywords"]) ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        var tags: [String] = []
        if let cuisine, !cuisine.isEmpty { tags.append(cuisine) }
        tags.append(contentsOf: keywordTags.prefix(5))

        return ParsedRecipeDraft(
            title: title,
            ingredients: ingredients,
            prepSteps: flattenedInstructions.prepSteps,
            steps: flattenedInstructions.steps,
            course: guessCourse(fromCategory: stringValue(recipe["recipeCategory"])),
            prepTimeMinutes: parseDuration(stringValue(recipe["prepTime"])),
            cookTimeMinutes: parseDuration(stringValue(recipe["cookTime"])),
            servings: parseYield(recipe["recipeYield"]),
            tags: tags,
            sourceURL: nil
        )
    }

    /// Flattens `recipeInstructions` into ordered prep/cook buckets. A `HowToSection`
    /// whose `name` mentions "prep" routes its entire contents to `prepSteps`, regardless
    /// of what's nested inside it; everything else — untitled steps, other section names —
    /// stays in `steps`. Most sites don't label a "Prep" section, so `prepSteps` simply
    /// stays empty for those — a safe, no-op default rather than a guess.
    private static func flattenInstructions(_ value: Any?) -> (prepSteps: [String], steps: [String]) {
        if let string = value as? String {
            let steps = string
                .split(whereSeparator: { $0.isNewline })
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            return ([], steps)
        }
        if let array = value as? [Any] {
            var prepSteps: [String] = []
            var steps: [String] = []
            for item in array {
                if let itemString = item as? String {
                    steps.append(itemString)
                } else if let dict = item as? [String: Any] {
                    let type = dict["@type"] as? String
                    if type == "HowToSection", let nested = dict["itemListElement"] {
                        let nestedResult = flattenInstructions(nested)
                        let sectionName = dict["name"] as? String
                        if let sectionName, sectionName.localizedCaseInsensitiveContains("prep") {
                            prepSteps.append(contentsOf: nestedResult.prepSteps + nestedResult.steps)
                        } else {
                            prepSteps.append(contentsOf: nestedResult.prepSteps)
                            steps.append(contentsOf: nestedResult.steps)
                        }
                    } else if let text = dict["text"] as? String {
                        steps.append(text)
                    } else if let name = dict["name"] as? String {
                        steps.append(name)
                    }
                }
            }
            let cleanedPrepSteps = prepSteps.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let cleanedSteps = steps.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return (cleanedPrepSteps, cleanedSteps)
        }
        return ([], [])
    }

    private static func parseDuration(_ iso: String?) -> Int? {
        guard let iso, iso.hasPrefix("PT") else { return nil }
        let ns = iso as NSString
        guard let match = durationPattern.firstMatch(in: iso, range: NSRange(location: 0, length: ns.length)) else {
            return nil
        }
        func value(_ index: Int) -> Int {
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return 0 }
            return Int(ns.substring(with: range)) ?? 0
        }
        let total = value(1) * 60 + value(2)
        return total > 0 ? total : nil
    }

    private static func parseYield(_ value: Any?) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let array = value as? [Any] {
            for item in array {
                if let result = parseYield(item) { return result }
            }
            return nil
        }
        if let string = value as? String {
            return leadingInt(in: string)
        }
        if let dict = value as? [String: Any], let inner = dict["value"] {
            return parseYield(inner)
        }
        return nil
    }

    private static func leadingInt(in string: String) -> Int? {
        let ns = string as NSString
        guard let match = leadingIntPattern.firstMatch(in: string, range: NSRange(location: 0, length: ns.length)) else {
            return nil
        }
        return Int(ns.substring(with: match.range))
    }

    private static func guessCourse(fromCategory category: String?) -> RecipeCourse? {
        guard let category = category?.lowercased() else { return nil }
        if category.contains("dessert") || category.contains("sweet") || category.contains("cake") || category.contains("cookie") {
            return .dessert
        }
        if category.contains("appetizer") || category.contains("starter") || category.contains("snack") || category.contains("side") {
            return .appetizer
        }
        if category.contains("entree") || category.contains("main") || category.contains("dinner") || category.contains("lunch") {
            return .entree
        }
        return nil
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&amp;", "&"), ("&quot;", "\""), ("&#039;", "'"), ("&apos;", "'"),
            ("&lt;", "<"), ("&gt;", ">"),
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }

    private static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String { return string }
        if let array = value as? [String] { return array.first }
        return nil
    }

    private static func stringArray(_ value: Any?) -> [String]? {
        if let array = value as? [String] { return array }
        if let single = value as? String { return [single] }
        return nil
    }

    private static func jsonLDBlocks(in html: String) -> [String] {
        let ns = html as NSString
        let matches = scriptBlockPattern.matches(in: html, range: NSRange(location: 0, length: ns.length))
        return matches.compactMap { match in
            guard match.range(at: 1).location != NSNotFound else { return nil }
            return ns.substring(with: match.range(at: 1))
        }
    }

    // MARK: - Static regexes

    private static let scriptBlockPattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: "<script[^>]+type=[\"']application/ld\\+json[\"'][^>]*>(.*?)</script>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
    }()

    private static let durationPattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "PT(?:(\\d+)H)?(?:(\\d+)M)?")
    }()

    private static let leadingIntPattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "\\d+")
    }()
}
