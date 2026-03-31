import Foundation
import SwiftUI

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var rules: [Rule] = []
    var profiles: [ChromeProfile] = []
    var defaultProfileDirectory: String = "Default"

    private init() {
        load()
        refreshProfiles()
    }

    func load() {
        let stored = RuleStorage.load()
        rules = stored.rules
        defaultProfileDirectory = stored.defaultProfile
    }

    func save() {
        RuleStorage.save(rules: rules, defaultProfile: defaultProfileDirectory)
    }

    func refreshProfiles() {
        profiles = ChromeProfileDiscovery.discoverProfiles()
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
