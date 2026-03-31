# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Browser Air Traffic Controller is a macOS menu-bar app (SwiftUI + AppKit) that acts as a default browser, intercepting HTTP/HTTPS links and routing them to specific browsers and profiles based on user-defined regex rules. Supports Chrome, Edge, Brave, Arc, Safari, and Firefox. Built with Swift 6.0, targeting macOS 14.0+.

## Build & Run Commands

```bash
make build      # Compile release binary via Swift Package Manager
make bundle     # Create .app bundle (includes ad-hoc code signing)
make install    # Install to ~/Applications
make run        # Build, bundle, and launch
make clean      # Remove build artifacts
```

The project uses Swift Package Manager (Package.swift) — no Xcode project file.

## Architecture

### URL Routing Flow

1. macOS delivers URL to `AppDelegate.application(_:open:)` (app is registered as default browser via Info.plist)
2. `URLMatcher.match()` tests URL against enabled rules in order (first match wins)
3. `BrowserLauncher.open()` opens the URL in the matched browser and profile
4. App shows a toast notification and stays in the menu bar

### Layer Structure

- **App/** — Entry points: `BrowserATCApp.swift` (@main SwiftUI app with MenuBarExtra), `AppDelegate.swift` (URL open handler)
- **Models/** — `AppState` (@MainActor @Observable singleton), `Rule` (pattern → browser + profile mapping), `BrowserDefinition` (browser brand with built-in definitions), `BrowserProfile` (browser-specific profile)
- **Services/** — `URLMatcher` (regex matching), `BrowserLauncher` (dispatches to Chromium/Safari/Firefox launch methods), `BrowserProfileDiscovery` (discovers profiles across all installed browsers), `RuleStorage` (JSON persistence to `~/Library/Application Support/BrowserATC/`)
- **Views/** — `ContentView` (root), `RuleListView` (drag-reorder list), `RuleEditorView` (sheet with browser + profile pickers), `SettingsView` (sheet)

### Key Design Decisions

- Menu-bar-only app (`LSUIElement = true` in Info.plist) with `MenuBarExtra` for settings access
- Multi-browser support via `BrowserDefinition.builtins` (Chrome, Edge, Brave, Arc, Safari, Firefox)
- Chromium browsers share profile discovery (Local State JSON) and launch logic (`--profile-directory`)
- Browser installation detected via `NSWorkspace` bundle ID lookup (handles non-standard install paths)
- State management via `AppState.shared` singleton using Swift Observation framework
- Rules are persisted as JSON; first-match-wins ordering (drag-to-reorder in UI)
- Backward-compatible JSON decoding: `Rule.browserID` defaults to "chrome" when absent
- App requires ad-hoc code signing to register as default browser (handled by `scripts/bundle.sh`)
