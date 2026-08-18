import Foundation

enum RecipePageFetcherError: Error {
    case invalidResponse
    case decodingFailed
}

/// Thin network wrapper for fetching a recipe page's HTML. Not unit-tested — kept
/// intentionally minimal so the parsing logic that consumes its output can be.
enum RecipePageFetcher {
    private static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Mobile/15E148 Safari/604.1"

    static func fetchHTML(from url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw RecipePageFetcherError.invalidResponse
        }

        if let text = String(data: data, encoding: .utf8) {
            return text
        }
        if let encodingName = response.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
            if nsEncoding != UInt(kCFStringEncodingInvalidId), let text = String(data: data, encoding: String.Encoding(rawValue: nsEncoding)) {
                return text
            }
        }
        throw RecipePageFetcherError.decodingFailed
    }
}
