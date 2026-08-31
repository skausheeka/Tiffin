import Foundation

enum TagNormalizer {
    /// Standard Title Case — each whitespace-separated word gets an uppercase first
    /// letter and a lowercased remainder. This is the canonical form new tags converge
    /// on, so "indian" and "INDIAN" both become "Indian" without needing to compare
    /// against anything else first.
    static func titleCased(_ tag: String) -> String {
        tag.split(separator: " ").map { word in
            guard let first = word.first else { return String(word) }
            return first.uppercased() + word.dropFirst().lowercased()
        }.joined(separator: " ")
    }

    /// Case-insensitive Levenshtein edit distance between two strings.
    static func levenshteinDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a.lowercased())
        let b = Array(b.lowercased())
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }

        var previous = Array(0...b.count)
        var current = [Int](repeating: 0, count: b.count + 1)

        for i in 1...a.count {
            current[0] = i
            for j in 1...b.count {
                if a[i - 1] == b[j - 1] {
                    current[j] = previous[j - 1]
                } else {
                    current[j] = 1 + min(previous[j - 1], previous[j], current[j - 1])
                }
            }
            previous = current
        }
        return previous[b.count]
    }

    /// Two different (non-identical) strings within a small, length-scaled edit
    /// distance are treated as a likely typo of one another — worth asking the user
    /// about — rather than two unrelated tags. Identical strings (ignoring case) are
    /// not a "typo": that's exact reuse, handled separately by `titleCased`.
    static func possibleTypo(_ a: String, _ b: String) -> Bool {
        let distance = levenshteinDistance(a, b)
        guard distance > 0 else { return false }
        let threshold = max(1, min(a.count, b.count) / 3)
        return distance <= threshold
    }
}
