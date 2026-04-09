import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var didHandleURLs = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.didHandleURLs {
                self.openMainWindow()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        didHandleURLs = true
        closeMainWindow()
        let state = AppState.shared
        var descriptions: [String] = []

        for url in urls {
            let rule = URLMatcher.match(url: url, against: state.rules)
            let browserID = rule?.browserID ?? state.defaultBrowserID
            let profileDirectory = rule?.profileDirectory ?? state.defaultProfileDirectory

            BrowserLauncher.open(url: url, browserID: browserID, profileDirectory: profileDirectory)

            let browserName = BrowserDefinition.builtins
                .first(where: { $0.id == browserID })?.name ?? browserID
            let profileName = state.profiles
                .first(where: { $0.browserID == browserID && $0.directory == profileDirectory })?
                .displayName
            if let profileName, !profileName.isEmpty, profileName != browserName {
                descriptions.append("\(browserName) / \(profileName)")
            } else {
                descriptions.append(browserName)
            }
        }

        let unique = Set(descriptions)
        let message: String
        if urls.count == 1 {
            message = "Opened in \(descriptions[0])"
        } else if unique.count == 1 {
            message = "Opened \(urls.count) URLs in \(descriptions[0])"
        } else {
            message = "Opened \(urls.count) URLs"
        }
        ToastWindow.show(message: message)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        // Bring existing main window to front
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            return
        }
        // Window was closed — ask SwiftUI to recreate it
        WindowManager.openWindow?(id: "main")
    }

    private func closeMainWindow() {
        for window in NSApp.windows where window.canBecomeMain {
            window.close()
        }
    }
}
