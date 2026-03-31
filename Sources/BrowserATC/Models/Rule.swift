import Foundation

struct Rule: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var pattern: String
    var browserID: String
    var profileDirectory: String
    var isEnabled: Bool

    init(id: UUID = UUID(), pattern: String, browserID: String = "chrome",
         profileDirectory: String, isEnabled: Bool = true) {
        self.id = id
        self.pattern = pattern
        self.browserID = browserID
        self.profileDirectory = profileDirectory
        self.isEnabled = isEnabled
    }

    var isValidPattern: Bool {
        (try? Regex(pattern)) != nil
    }

    private enum CodingKeys: String, CodingKey {
        case id, pattern, browserID, profileDirectory, isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        pattern = try container.decode(String.self, forKey: .pattern)
        browserID = try container.decodeIfPresent(String.self, forKey: .browserID) ?? "chrome"
        profileDirectory = try container.decode(String.self, forKey: .profileDirectory)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }
}
