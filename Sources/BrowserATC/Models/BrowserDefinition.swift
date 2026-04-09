import AppKit

enum BrowserType: String, Codable, Sendable {
    case chromium
    case safari
    case firefox
    case adspower
}

struct BrowserDefinition: Identifiable, Codable, Sendable, Equatable {
    let id: String
    let name: String
    let bundleID: String
    let browserType: BrowserType
    let localStatePath: String?

    static let builtins: [BrowserDefinition] = [
        BrowserDefinition(
            id: "chrome",
            name: "Google Chrome",
            bundleID: "com.google.Chrome",
            browserType: .chromium,
            localStatePath: "Google/Chrome/Local State"
        ),
        BrowserDefinition(
            id: "edge",
            name: "Microsoft Edge",
            bundleID: "com.microsoft.edgemac",
            browserType: .chromium,
            localStatePath: "Microsoft Edge/Local State"
        ),
        BrowserDefinition(
            id: "brave",
            name: "Brave Browser",
            bundleID: "com.brave.Browser",
            browserType: .chromium,
            localStatePath: "BraveSoftware/Brave-Browser/Local State"
        ),
        BrowserDefinition(
            id: "arc",
            name: "Arc",
            bundleID: "company.thebrowser.Browser",
            browserType: .chromium,
            localStatePath: "Arc/User Data/Local State"
        ),
        BrowserDefinition(
            id: "safari",
            name: "Safari",
            bundleID: "com.apple.Safari",
            browserType: .safari,
            localStatePath: nil
        ),
        BrowserDefinition(
            id: "firefox",
            name: "Firefox",
            bundleID: "org.mozilla.firefox",
            browserType: .firefox,
            localStatePath: "Firefox/profiles.ini"
        ),
        BrowserDefinition(
            id: "adspower",
            name: "AdsPower",
            bundleID: "com.adspower.global",
            browserType: .adspower,
            localStatePath: nil
        ),
    ]

    @MainActor
    static func isInstalled(_ browser: BrowserDefinition) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID) != nil
    }

    @MainActor
    static func appURL(for browser: BrowserDefinition) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID)
    }
}
