import Foundation

enum URLMatcher {
    /// Returns the first enabled rule whose regex pattern matches the URL string, or nil.
    static func match(url: URL, against rules: [Rule]) -> Rule? {
        let urlString = url.absoluteString
        return rules
            .filter(\.isEnabled)
            .first { rule in
                guard let regex = try? Regex(rule.pattern) else { return false }
                return urlString.firstMatch(of: regex) != nil
            }
    }
}
