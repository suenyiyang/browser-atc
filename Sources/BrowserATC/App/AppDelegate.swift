import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var didHandleURLs = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.didHandleURLs {
                self.openSettings()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openSettings()
        }
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        didHandleURLs = true
        let state = AppState.shared
        var profileNames: [String] = []

        for url in urls {
            let profileDirectory = URLMatcher.match(url: url, against: state.rules)?
                .profileDirectory ?? state.defaultProfileDirectory
            ChromeLauncher.open(url: url, profileDirectory: profileDirectory)

            let profileName = state.profiles
                .first(where: { $0.directory == profileDirectory })?.displayName
                ?? profileDirectory
            profileNames.append(profileName)
        }

        let uniqueProfiles = Set(profileNames)
        let message: String
        if urls.count == 1 {
            message = "Opened in \(profileNames[0])"
        } else if uniqueProfiles.count == 1 {
            message = "Opened \(urls.count) URLs in \(profileNames[0])"
        } else {
            message = "Opened \(urls.count) URLs"
        }
        ToastWindow.show(message: message)
    }

    private func openSettings() {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
