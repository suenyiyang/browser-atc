import AppKit

enum BrowserLauncher {
    @MainActor
    static func open(url: URL, browserID: String, profileDirectory: String) {
        guard let browser = BrowserDefinition.builtins.first(where: { $0.id == browserID }) else {
            NSWorkspace.shared.open(url)
            return
        }

        switch browser.browserType {
        case .chromium:
            openChromium(url: url, browser: browser, profileDirectory: profileDirectory)
        case .safari:
            openWithWorkspace(url: url, browser: browser)
        case .firefox:
            openFirefox(url: url, browser: browser, profileDirectory: profileDirectory)
        }
    }

    @MainActor
    private static func openChromium(url: URL, browser: BrowserDefinition, profileDirectory: String) {
        guard let appURL = BrowserDefinition.appURL(for: browser) else {
            NSWorkspace.shared.open(url)
            return
        }

        let binaryPath = appURL.path + "/Contents/MacOS/" + binaryName(for: browser)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = [
            "--profile-directory=\(profileDirectory)",
            url.absoluteString,
        ]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        activateBrowser(browser)
    }

    @MainActor
    private static func openWithWorkspace(url: URL, browser: BrowserDefinition) {
        guard let appURL = BrowserDefinition.appURL(for: browser) else {
            NSWorkspace.shared.open(url)
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: configuration
        )
    }

    @MainActor
    private static func openFirefox(url: URL, browser: BrowserDefinition, profileDirectory: String) {
        guard let appURL = BrowserDefinition.appURL(for: browser) else {
            NSWorkspace.shared.open(url)
            return
        }

        let binaryPath = appURL.path + "/Contents/MacOS/firefox"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        if profileDirectory.isEmpty {
            process.arguments = [url.absoluteString]
        } else {
            process.arguments = ["-P", profileDirectory, url.absoluteString]
        }
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        activateBrowser(browser)
    }

    private static func activateBrowser(_ browser: BrowserDefinition) {
        NSRunningApplication.runningApplications(withBundleIdentifier: browser.bundleID).first?.activate()
    }

    private static func binaryName(for browser: BrowserDefinition) -> String {
        switch browser.id {
        case "chrome": return "Google Chrome"
        case "edge": return "Microsoft Edge"
        case "brave": return "Brave Browser"
        case "arc": return "Arc"
        default: return browser.name
        }
    }
}
