import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, @unchecked Sendable {
    func application(_ application: NSApplication, open urls: [URL]) {
        let state = AppState.shared
        for url in urls {
            let profileDirectory = URLMatcher.match(url: url, against: state.rules)?
                .profileDirectory ?? state.defaultProfileDirectory
            ChromeLauncher.open(url: url, profileDirectory: profileDirectory)
        }
        // Don't steal focus — hide ourselves after routing
        NSApp.hide(nil)
    }
}
