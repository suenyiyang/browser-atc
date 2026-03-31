import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: AppState
    @State private var testURL: String = ""

    private var matchResult: String {
        guard !testURL.isEmpty, let url = URL(string: testURL) else { return "" }
        if let rule = URLMatcher.match(url: url, against: state.rules) {
            let profileName = state.profiles
                .first(where: { $0.directory == rule.profileDirectory })?.displayName
                ?? rule.profileDirectory
            return "Matches rule \"\(rule.pattern)\" → \(profileName)"
        } else {
            let defaultName = state.profiles
                .first(where: { $0.directory == state.defaultProfileDirectory })?.displayName
                ?? state.defaultProfileDirectory
            return "No rule matched → default profile: \(defaultName)"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Default Profile") {
                    if state.profiles.isEmpty {
                        Text("No Chrome profiles found.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Fallback profile for unmatched URLs", selection: Binding(
                            get: { state.defaultProfileDirectory },
                            set: {
                                state.defaultProfileDirectory = $0
                                state.save()
                            }
                        )) {
                            ForEach(state.profiles) { profile in
                                Text(profile.displayName)
                                    .tag(profile.directory)
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

                Section("Chrome") {
                    HStack {
                        if ChromeProfileDiscovery.isChromeInstalled {
                            Label("Chrome is installed", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Chrome not found", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }

                        Spacer()

                        Button("Refresh Profiles") {
                            state.refreshProfiles()
                        }
                    }

                    Text("\(state.profiles.count) profile(s) detected")
                        .foregroundStyle(.secondary)
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
        .frame(width: 500, height: 380)
    }
}
