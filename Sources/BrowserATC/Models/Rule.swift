import Foundation

struct Rule: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var pattern: String
    var profileDirectory: String
    var isEnabled: Bool

    init(id: UUID = UUID(), pattern: String, profileDirectory: String, isEnabled: Bool = true) {
        self.id = id
        self.pattern = pattern
        self.profileDirectory = profileDirectory
        self.isEnabled = isEnabled
    }

    var isValidPattern: Bool {
        (try? Regex(pattern)) != nil
    }
}
