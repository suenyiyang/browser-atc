# Browser Air Traffic Controller

A macOS app that routes URLs to different Google Chrome profiles based on regex rules. Set it as your default browser, and every link you click automatically opens in the right Chrome profile — work links go to your work profile, personal links to your personal profile, and so on.

## Requirements

- macOS 14.0+
- Swift 6.0 toolchain
- Google Chrome installed

## Installation

```bash
make install
```

This builds the app and copies it to `~/Applications/BrowserATC.app`.

After installation, open the app once, then go to **System Settings → Desktop & Dock → Default web browser** and select **Browser Air Traffic Controller**.

## Usage

### Adding Rules

Click the **+** button to create a routing rule. Each rule has:

- **Pattern** — a regex matched against the full URL (e.g. `github\.com/my-org` or `.*\.slack\.com`)
- **Profile** — the Chrome profile to open matching URLs in
- **Enabled** — toggle rules on/off without deleting them

Rules are evaluated top-to-bottom; the first match wins. Drag to reorder.

### Default Profile

In **Settings**, pick a fallback Chrome profile for URLs that don't match any rule.

### Testing

Use the **Test URL** field in Settings to check which rule (if any) matches a given URL before you commit to it.

## Development

```bash
make build    # Compile release binary
make run      # Build, bundle, and launch the app
make clean    # Remove build artifacts
```

The project uses Swift Package Manager — no Xcode project required. You can also open the directory in Xcode via `open Package.swift`.

## How It Works

The app registers as a browser handler for `http`/`https` schemes via its `Info.plist`. When macOS routes a URL to it, the app matches the URL against your rules using Swift's `Regex` API, launches Chrome with the `--profile-directory` flag for the matched profile, and immediately hides itself.

Chrome profiles are auto-detected by reading Chrome's `Local State` file. Rules are stored as JSON in `~/Library/Application Support/BrowserATC/`.

## License

[Apache License 2.0](LICENSE)
