import Foundation

struct LatestRelease: Sendable {
    let version: String
    let htmlURL: URL
    let publishedAt: Date?
    let body: String?
}

enum UpdateCheckError: Error, LocalizedError {
    case invalidResponse
    case decodingFailed
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "GitHub returned an unexpected response."
        case .decodingFailed: "Could not parse the latest release."
        case .network(let message): message
        }
    }
}

enum UpdateChecker {
    static let releasesAPI = URL(string: "https://api.github.com/repos/suenyiyang/browser-atc/releases/latest")!
    static let lastCheckKey = "UpdateChecker.lastCheckTimestamp"
    static let throttleInterval: TimeInterval = 60 * 60 * 24 // 24h

    static var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static func shouldAutoCheck(now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        let last = defaults.double(forKey: lastCheckKey)
        guard last > 0 else { return true }
        return now.timeIntervalSince1970 - last >= throttleInterval
    }

    static func recordCheck(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now.timeIntervalSince1970, forKey: lastCheckKey)
    }

    static func fetchLatest(session: URLSession = .shared) async throws -> LatestRelease {
        var request = URLRequest(url: releasesAPI)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.timeoutInterval = 15

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UpdateCheckError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw UpdateCheckError.invalidResponse
        }

        struct Payload: Decodable {
            let tag_name: String
            let html_url: String
            let published_at: String?
            let body: String?
        }

        guard let payload = try? JSONDecoder().decode(Payload.self, from: data),
              let url = URL(string: payload.html_url) else {
            throw UpdateCheckError.decodingFailed
        }

        let formatter = ISO8601DateFormatter()
        return LatestRelease(
            version: stripLeadingV(payload.tag_name),
            htmlURL: url,
            publishedAt: payload.published_at.flatMap { formatter.date(from: $0) },
            body: payload.body
        )
    }

    /// Returns true when `latest` is strictly greater than `current` using semver-ish numeric comparison.
    /// Non-numeric components are treated as 0; a longer numeric prefix beats a shorter one.
    static func isNewer(latest: String, than current: String) -> Bool {
        let lhs = numericComponents(latest)
        let rhs = numericComponents(current)
        let count = max(lhs.count, rhs.count)
        for i in 0..<count {
            let a = i < lhs.count ? lhs[i] : 0
            let b = i < rhs.count ? rhs[i] : 0
            if a != b { return a > b }
        }
        return false
    }

    private static func stripLeadingV(_ tag: String) -> String {
        guard let first = tag.first, first == "v" || first == "V" else { return tag }
        return String(tag.dropFirst())
    }

    private static func numericComponents(_ version: String) -> [Int] {
        stripLeadingV(version)
            .split(whereSeparator: { !$0.isNumber })
            .map { Int($0) ?? 0 }
    }
}
