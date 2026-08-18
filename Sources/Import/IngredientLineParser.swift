import Foundation

/// Best-effort parser for a single ingredient line (e.g. "2 cups all-purpose flour",
/// "1/2 tsp salt", "Kosher salt, to taste") into amount/unit/name. Falls back to putting
/// the whole line in `name` when nothing recognizable is found — always safe, since the
/// user reviews every row in `AddRecipeView` before saving.
enum IngredientLineParser {
    private static let vulgarFractionValues: [Character: Double] = [
        "½": 1.0 / 2.0, "⅓": 1.0 / 3.0, "⅔": 2.0 / 3.0, "¼": 1.0 / 4.0, "¾": 3.0 / 4.0,
        "⅕": 1.0 / 5.0, "⅖": 2.0 / 5.0, "⅗": 3.0 / 5.0, "⅘": 4.0 / 5.0,
        "⅙": 1.0 / 6.0, "⅚": 5.0 / 6.0, "⅛": 1.0 / 8.0, "⅜": 3.0 / 8.0, "⅝": 5.0 / 8.0, "⅞": 7.0 / 8.0,
    ]

    private static let vulgarFractionCharacterClass = String(vulgarFractionValues.keys)

    /// Alternatives, tried in order: mixed number ("1 1/2"), plain fraction ("1/2"),
    /// decimal ("1.5"), integer with an optional trailing vulgar fraction ("1", "1½"),
    /// or a bare vulgar fraction ("½"). Followed by an optional discarded range suffix
    /// ("-4" / " to 4") so a range like "3-4 cloves" resolves to its first number.
    private static let amountPattern: NSRegularExpression = {
        let pattern = "^(?:"
            + "(\\d+)\\s+(\\d+)/(\\d+)"
            + "|(\\d+)/(\\d+)"
            + "|(\\d+\\.\\d+)"
            + "|(\\d+)([\(vulgarFractionCharacterClass)])?"
            + "|([\(vulgarFractionCharacterClass)])"
            + ")"
            + "(?:\\s*(?:-|–|to)\\s*\\d+(?:\\.\\d+)?)?"
        // swiftlint:disable:next force_try
        return try! NSRegularExpression(pattern: pattern)
    }()

    private static let unitWords: Set<String> = {
        var words = Set(IngredientUnitSuggestions.allUnits.map { $0.lowercased() })
        words.formUnion([
            "cups", "tbsps", "tablespoon", "tablespoons", "tsps", "teaspoon", "teaspoons",
            "lbs", "pound", "pounds", "ounce", "ounces", "gram", "grams", "g", "kg",
            "kilogram", "kilograms", "ml", "milliliter", "milliliters", "l", "liter",
            "liters", "litre", "litres", "cloves", "sprigs", "heads", "ears", "cans",
            "inch", "inches", "loaves", "bunches", "stalks", "pinches", "piece", "pieces",
            "slice", "slices", "stick", "sticks", "quart", "quarts", "pint", "pints",
            "gallon", "gallons", "package", "packages", "bag", "bags",
        ])
        return words
    }()

    static func parse(_ rawLine: String) -> IngredientEntry {
        let line = stripLeadingBullet(rawLine.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !line.isEmpty else { return IngredientEntry(name: "") }

        guard let (amount, restIndex) = consumeAmount(from: line) else {
            return IngredientEntry(name: line)
        }

        let rest = String(line[restIndex...]).trimmingCharacters(in: .whitespaces)
        let (unit, remainder) = consumeUnit(from: rest)
        let name = remainder.trimmingCharacters(in: .whitespaces)

        return IngredientEntry(name: name.isEmpty ? line : name, amount: amount, unit: unit)
    }

    private static func stripLeadingBullet(_ line: String) -> String {
        for marker in ["- ", "– ", "* ", "• ", "◦ "] where line.hasPrefix(marker) {
            return String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
        }
        return line
    }

    private static func consumeAmount(from line: String) -> (Double, String.Index)? {
        let nsLine = line as NSString
        guard let match = amountPattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return nil
        }

        func group(_ index: Int) -> String? {
            let range = match.range(at: index)
            guard range.location != NSNotFound else { return nil }
            return nsLine.substring(with: range)
        }

        let amount: Double?
        if let whole = group(1), let num = group(2), let denom = group(3), let denomValue = Double(denom), denomValue != 0 {
            amount = (Double(whole) ?? 0) + (Double(num) ?? 0) / denomValue
        } else if let num = group(4), let denom = group(5), let denomValue = Double(denom), denomValue != 0 {
            amount = (Double(num) ?? 0) / denomValue
        } else if let decimal = group(6) {
            amount = Double(decimal)
        } else if let whole = group(7) {
            var value = Double(whole) ?? 0
            if let fractionChar = group(8)?.first, let fractionValue = vulgarFractionValues[fractionChar] {
                value += fractionValue
            }
            amount = value
        } else if let fractionChar = group(9)?.first {
            amount = vulgarFractionValues[fractionChar]
        } else {
            amount = nil
        }

        guard let amount, let range = Range(match.range, in: line) else { return nil }
        return (amount, range.upperBound)
    }

    private static func consumeUnit(from text: String) -> (unit: String, remainder: String) {
        guard let wordRange = text.range(of: "^[A-Za-z]+", options: .regularExpression) else {
            return ("", text)
        }
        let word = String(text[wordRange])
        guard unitWords.contains(word.lowercased()) else {
            return ("", text)
        }
        return (word, String(text[wordRange.upperBound...]))
    }
}
