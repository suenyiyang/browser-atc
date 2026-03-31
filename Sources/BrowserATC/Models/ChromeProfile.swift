import Foundation

struct ChromeProfile: Identifiable, Codable, Sendable, Equatable {
    var id: String { directory }
    let directory: String
    let displayName: String
}
