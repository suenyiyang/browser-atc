import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: AppState
    @State private var testURL: String = ""

    private var matchResult: String {
        guard !testURL.isEmpty, let url = URL(string: testURL) else { return "" }
        if let rule = URLMatcher.match(url: url, against: state.rules) {
            let browserName = BrowserDefinition.builtins
                .first(where: { $0.id == rule.browserID })?.name ?? rule.browserID
            let profileName = state.profiles
                .first(where: { $0.browserID == rule.browserID && $0.directory == rule.profileDirectory })?
                .displayName
            if let profileName, !profileName.isEmpty, profileName != browserName {
                return "Matches rule \"\(rule.pattern)\" \u{2192} \(browserName) / \(profileName)"
            }
            return "Matches rule \"\(rule.pattern)\" \u{2192} \(browserName)"
        } else {
            let browserName = BrowserDefinition.builtins
                .first(where: { $0.id == state.defaultBrowserID })?.name ?? state.defaultBrowserID
            let profileName = state.profiles
                .first(where: { $0.browserID == state.defaultBrowserID && $0.directory == state.defaultProfileDirectory })?
                .displayName
            if let profileName, !profileName.isEmpty, profileName != browserName {
                return "No rule matched \u{2192} default: \(browserName) / \(profileName)"
            }
            return "No rule matched \u{2192} default: \(browserName)"
        }
    }

    private var defaultBrowserProfiles: [BrowserProfile] {
        state.profiles(for: state.defaultBrowserID)
    }

    private var defaultBrowserHasProfiles: Bool {
        BrowserDefinition.builtins
            .first(where: { $0.id == state.defaultBrowserID })?.browserType != .safari
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Default Browser") {
                    if state.installedBrowsers.isEmpty {
                        Text("No browsers found.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Browser", selection: Binding(
                            get: { state.defaultBrowserID },
                            set: {
                                state.defaultBrowserID = $0
                                let profiles = state.profiles(for: $0)
                                state.defaultProfileDirectory = profiles.first?.directory ?? ""
                                state.save()
                            }
                        )) {
                            ForEach(state.installedBrowsers) { browser in
                                Text(browser.name)
                                    .tag(browser.id)
                            }
                        }

                        if defaultBrowserHasProfiles {
                            if defaultBrowserProfiles.isEmpty {
                                Text("No profiles found.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Fallback profile for unmatched URLs", selection: Binding(
                                    get: { state.defaultProfileDirectory },
                                    set: {
                                        state.defaultProfileDirectory = $0
                                        state.save()
                                    }
                                )) {
                                    ForEach(defaultBrowserProfiles) { profile in
                                        Text(profile.displayName)
                                            .tag(profile.directory)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Test URL") {
                    TextField("Paste a URL to test rule matching", text: $testURL)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))

                    if !testURL.isEmpty {
                        Text(matchResult)
                            .font(.callout)
                            .foregroundStyle(
                                matchResult.contains("Matches rule") ? .green : .secondary
                            )
                    }
                }

                Section("Browsers") {
                    ForEach(BrowserDefinition.builtins) { browser in
                        HStack {
                            let installed = BrowserDefinition.isInstalled(browser)
                            Label(browser.name, systemImage: installed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(installed ? .green : .secondary)

                            Spacer()

                            let count = state.profiles(for: browser.id).count
                            if installed && browser.browserType != .safari {
                                Text("\(count) profile(s)")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    }

                    Button("Refresh Profiles") {
                        state.refreshProfiles()
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(minWidth: 350, idealWidth: 450, minHeight: 380, idealHeight: 480)
    }
}
