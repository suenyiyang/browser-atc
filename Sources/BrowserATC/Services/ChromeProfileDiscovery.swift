import Foundation

enum ChromeProfileDiscovery {
    private static let chromeAppSupportPath =
        NSHomeDirectory() + "/Library/Application Support/Google/Chrome"

    static func discoverProfiles() -> [ChromeProfile] {
        let localStatePath = chromeAppSupportPath + "/Local State"

        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: localStatePath)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profileSection = json["profile"] as? [String: Any],
            let infoCache = profileSection["info_cache"] as? [String: [String: Any]]
        else {
            return []
        }

        return infoCache.compactMap { directory, profileData in
            guard let name = profileData["name"] as? String else { return nil }
            return ChromeProfile(directory: directory, displayName: name)
        }
        .sorted { lhs, rhs in
            if lhs.directory == "Default" { return true }
            if rhs.directory == "Default" { return false }
            return lhs.displayName.localizedCompare(rhs.displayName) == .orderedAscending
        }
    }

    static var isChromeInstalled: Bool {
        FileManager.default.fileExists(atPath: "/Applications/Google Chrome.app")
    }
}
