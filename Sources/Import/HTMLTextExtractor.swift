import Foundation

/// Strips a web page down to plain text for the LLM fallback path — used only when a URL's
/// page has no usable JSON-LD `Recipe` data. Not attempted for pasted raw text, which is
/// already plain.
enum HTMLTextExtractor {
    /// Caps the output so a page's comment section (which follows the recipe content in
    /// document order on virtually every recipe site) doesn't drown out the actual recipe
    /// or blow up the LLM request's token count.
    private static let maxCharacters = 12_000

    static func plainText(from html: String) -> String {
        var text = html
        text = replacing(scriptOrStylePattern, in: text, with: " ")
        text = replacing(tagPattern, in: text, with: " ")
        text = decodeHTMLEntities(text)
        text = collapseWhitespace(text)

        if text.count > maxCharacters {
            text = String(text.prefix(maxCharacters))
        }
        return text
    }

    private static func replacing(_ pattern: NSRegularExpression, in text: String, with replacement: String) -> String {
        let ns = text as NSString
        return pattern.stringByReplacingMatches(
            in: text,
            range: NSRange(location: 0, length: ns.length),
            withTemplate: replacement
        )
    }

    private static func collapseWhitespace(_ text: String) -> String {
        let ns = text as NSString
        let collapsed = whitespacePattern.stringByReplacingMatches(
            in: text,
            range: NSRange(location: 0, length: ns.length),
            withTemplate: " "
        )
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities: [(String, String)] = [
            ("&nbsp;", " "), ("&amp;", "&"), ("&quot;", "\""), ("&#039;", "'"), ("&apos;", "'"),
            ("&lt;", "<"), ("&gt;", ">"),
        ]
        for (entity, replacement) in entities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        return result
    }

    private static let scriptOrStylePattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(
            pattern: "<(script|style)[^>]*>.*?</\\1>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        )
    }()

    private static let tagPattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "<[^>]+>")
    }()

    private static let whitespacePattern: NSRegularExpression = {
        // swiftlint:disable:next force_try
        try! NSRegularExpression(pattern: "\\s+")
    }()
}
