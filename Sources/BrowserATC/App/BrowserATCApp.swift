import SwiftUI

@main
struct BrowserATCApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(state: AppState.shared)
        }
        .defaultSize(width: 700, height: 500)
    }
}
