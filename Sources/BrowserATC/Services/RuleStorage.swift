import Foundation

enum RuleStorage {
    private static let appSupportDir: String = {
        let path = NSHomeDirectory() + "/Library/Application Support/BrowserATC"
        try? FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true
        )
        return path
    }()

    private static var filePath: String {
        appSupportDir + "/rules.json"
    }

    struct StoredData: Codable {
        var rules: [Rule]
        var defaultProfile: String
    }

    static func load() -> (rules: [Rule], defaultProfile: String) {
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
            let stored = try? JSONDecoder().decode(StoredData.self, from: data)
        else {
            return (rules: [], defaultProfile: "Default")
        }
        return (rules: stored.rules, defaultProfile: stored.defaultProfile)
    }

    static func save(rules: [Rule], defaultProfile: String) {
        let stored = StoredData(rules: rules, defaultProfile: defaultProfile)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }
}
