import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var rules: [Rule] = []
    var profiles: [BrowserProfile] = []
    var defaultBrowserID: String = "chrome"
    var defaultProfileDirectory: String = "Default"

    var installedBrowsers: [BrowserDefinition] {
        BrowserDefinition.builtins.filter { BrowserDefinition.isInstalled($0) }
    }

    private init() {
        load()
        refreshProfiles()
    }

    func load() {
        let stored = RuleStorage.load()
        rules = stored.rules
        defaultBrowserID = stored.defaultBrowserID
        defaultProfileDirectory = stored.defaultProfile
    }

    func save() {
        RuleStorage.save(rules: rules, defaultBrowserID: defaultBrowserID, defaultProfile: defaultProfileDirectory)
    }

    func refreshProfiles() {
        profiles = BrowserProfileDiscovery.discoverAllProfiles()
    }

    func profiles(for browserID: String) -> [BrowserProfile] {
        profiles.filter { $0.browserID == browserID }
    }

    func addRule(_ rule: Rule) {
        rules.append(rule)
        save()
    }

    func updateRule(_ rule: Rule) {
        guard let index = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[index] = rule
        save()
    }

    func deleteRules(at offsets: IndexSet) {
        rules.remove(atOffsets: offsets)
        save()
    }

    func moveRules(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)
        save()
    }
}
