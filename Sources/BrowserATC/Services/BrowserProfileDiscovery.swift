import AppKit

enum BrowserProfileDiscovery {
    @MainActor
    static func discoverAllProfiles() -> [BrowserProfile] {
        BrowserDefinition.builtins
            .filter { BrowserDefinition.isInstalled($0) }
            .flatMap { discoverProfiles(for: $0) }
    }

    static func discoverProfiles(for browser: BrowserDefinition) -> [BrowserProfile] {
        switch browser.browserType {
        case .chromium:
            return discoverChromiumProfiles(browser: browser)
        case .safari:
            return [BrowserProfile(browserID: browser.id, directory: "", displayName: browser.name)]
        case .firefox:
            return discoverFirefoxProfiles(browser: browser)
        }
    }

    private static func discoverChromiumProfiles(browser: BrowserDefinition) -> [BrowserProfile] {
        guard let localStatePath = browser.localStatePath else { return [] }
        let fullPath = NSHomeDirectory() + "/Library/Application Support/" + localStatePath

        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: fullPath)),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let profileSection = json["profile"] as? [String: Any],
            let infoCache = profileSection["info_cache"] as? [String: [String: Any]]
        else {
            return []
        }

        return infoCache.compactMap { directory, profileData in
            guard let name = profileData["name"] as? String else { return nil }
            return BrowserProfile(browserID: browser.id, directory: directory, displayName: name)
        }
        .sorted { lhs, rhs in
            if lhs.directory == "Default" { return true }
            if rhs.directory == "Default" { return false }
            return lhs.displayName.localizedCompare(rhs.displayName) == .orderedAscending
        }
    }

    private static func discoverFirefoxProfiles(browser: BrowserDefinition) -> [BrowserProfile] {
        guard let localStatePath = browser.localStatePath else { return [] }
        let fullPath = NSHomeDirectory() + "/Library/Application Support/" + localStatePath

        guard let content = try? String(contentsOfFile: fullPath, encoding: .utf8) else {
            return []
        }

        var profiles: [BrowserProfile] = []
        var currentName: String?

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("[") {
                if let name = currentName {
                    profiles.append(BrowserProfile(browserID: browser.id, directory: name, displayName: name))
                }
                currentName = nil
            } else if trimmed.lowercased().hasPrefix("name=") {
                currentName = String(trimmed.dropFirst(5))
            }
        }
        if let name = currentName {
            profiles.append(BrowserProfile(browserID: browser.id, directory: name, displayName: name))
        }

        return profiles
    }
}
