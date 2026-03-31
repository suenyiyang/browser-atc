import Foundation

struct BrowserProfile: Identifiable, Codable, Sendable, Equatable {
    var id: String { "\(browserID)/\(directory)" }
    let browserID: String
    let directory: String
    let displayName: String
}
