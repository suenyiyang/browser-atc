import SwiftUI

@main
struct BrowserATCApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            ContentView(state: AppState.shared)
        }
    }
}
