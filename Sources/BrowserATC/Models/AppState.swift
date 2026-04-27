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

    let currentVersion: String = UpdateChecker.currentVersion
    var latestRelease: LatestRelease?
    var isCheckingForUpdates: Bool = false
    var updateCheckError: String?
    var updateBannerDismissedForVersion: String?

    var isUpdateAvailable: Bool {
        guard let latest = latestRelease else { return false }
        return UpdateChecker.isNewer(latest: latest.version, than: currentVersion)
    }

    var shouldShowUpdateBanner: Bool {
        guard isUpdateAvailable, let latest = latestRelease else { return false }
        return updateBannerDismissedForVersion != latest.version
    }

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

    func checkForUpdates(force: Bool = false) {
        if !force && !UpdateChecker.shouldAutoCheck() { return }
        if isCheckingForUpdates { return }
        isCheckingForUpdates = true
        updateCheckError = nil

        Task { @MainActor in
            defer { isCheckingForUpdates = false }
            do {
                let release = try await UpdateChecker.fetchLatest()
                latestRelease = release
                UpdateChecker.recordCheck()
                if force {
                    if UpdateChecker.isNewer(latest: release.version, than: currentVersion) {
                        updateBannerDismissedForVersion = nil
                    } else {
                        ToastWindow.show(message: "You're on the latest version (v\(currentVersion)).")
                    }
                }
            } catch {
                let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                updateCheckError = message
                if force {
                    ToastWindow.show(message: "Update check failed: \(message)")
                }
            }
        }
    }

    func dismissUpdateBanner() {
        updateBannerDismissedForVersion = latestRelease?.version
    }
}
