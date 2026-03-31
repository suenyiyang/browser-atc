# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Browser Air Traffic Controller is a macOS app (SwiftUI + AppKit) that acts as a default browser, intercepting HTTP/HTTPS links and routing them to specific Google Chrome profiles based on user-defined regex rules. Built with Swift 6.0, targeting macOS 14.0+.

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
3. `ChromeLauncher.open()` spawns Chrome with the matched profile
4. App hides itself after routing

### Layer Structure

- **App/** — Entry points: `BrowserATCApp.swift` (@main SwiftUI app), `AppDelegate.swift` (URL open handler)
- **Models/** — `AppState` (@MainActor @Observable singleton), `Rule` (pattern → profile mapping), `ChromeProfile`
- **Services/** — `URLMatcher` (regex matching), `ChromeLauncher` (process spawn), `ChromeProfileDiscovery` (parses Chrome's Local State JSON), `RuleStorage` (JSON persistence to `~/Library/Application Support/BrowserATC/`)
- **Views/** — `ContentView` (root), `RuleListView` (drag-reorder list), `RuleEditorView` (sheet), `SettingsView` (sheet)

### Key Design Decisions

- State management via `AppState.shared` singleton using Swift Observation framework
- Rules are persisted as JSON; first-match-wins ordering (drag-to-reorder in UI)
- Chrome profiles discovered by parsing `~/Library/Application Support/Google/Chrome/Local State`
- App requires ad-hoc code signing to register as default browser (handled by `scripts/bundle.sh`)
