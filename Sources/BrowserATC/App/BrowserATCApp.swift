import SwiftUI

@main
struct BrowserATCApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("BrowserATC", systemImage: "airplane.circle") {
            MenuBarView()
        }

        Window("Browser ATC", id: "main") {
            ContentView(state: AppState.shared)
        }
        .defaultSize(width: 420, height: 400)
    }
}

private struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Settings...") {
            NSApp.activate()
            openWindow(id: "main")
        }
        .keyboardShortcut(",", modifiers: .command)
        Divider()
        Button("Quit BrowserATC") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}
