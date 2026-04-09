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
        case .adspower:
            return discoverAdsPowerProfiles(browser: browser)
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

    private static func discoverAdsPowerProfiles(browser: BrowserDefinition) -> [BrowserProfile] {
        let apiPort = readAdsPowerAPIPort() ?? "50325"
        let urlString = "http://local.adspower.net:\(apiPort)/api/v1/user/list?page_size=100"
        guard let url = URL(string: urlString) else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        guard
            let data = sendSynchronousRequest(request),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let code = json["code"] as? Int, code == 0,
            let dataObj = json["data"] as? [String: Any],
            let list = dataObj["list"] as? [[String: Any]]
        else { return [] }

        return list.compactMap { profile in
            guard let userID = profile["user_id"] as? String else { return nil }
            let name = profile["name"] as? String
            let serialNumber = profile["serial_number"] as? Int
            let displayName = name ?? "Profile \(serialNumber ?? 0)"
            return BrowserProfile(browserID: browser.id, directory: userID, displayName: displayName)
        }
        .sorted { $0.displayName.localizedCompare($1.displayName) == .orderedAscending }
    }

    private static func sendSynchronousRequest(_ request: URLRequest) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        nonisolated(unsafe) var responseData: Data?
        URLSession.shared.dataTask(with: request) { data, _, _ in
            responseData = data
            semaphore.signal()
        }.resume()
        _ = semaphore.wait(timeout: .now() + 5)
        return responseData
    }

    private static func readAdsPowerAPIPort() -> String? {
        let path = NSHomeDirectory() + "/Library/Application Support/adspower_global/cwd_global/source/local_api"
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        // The file contains the API address like "127.0.0.1:50325"
        if let colonIndex = trimmed.lastIndex(of: ":") {
            return String(trimmed[trimmed.index(after: colonIndex)...])
        }
        return nil
    }
}
