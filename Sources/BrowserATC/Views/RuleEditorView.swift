import SwiftUI

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pattern: String
    @State private var browserID: String
    @State private var profileDirectory: String
    @State private var isEnabled: Bool

    private let existingRule: Rule?
    private let installedBrowsers: [BrowserDefinition]
    private let allProfiles: [BrowserProfile]
    private let onSave: (Rule) -> Void

    init(rule: Rule? = nil, installedBrowsers: [BrowserDefinition],
         allProfiles: [BrowserProfile], onSave: @escaping (Rule) -> Void) {
        self.existingRule = rule
        self.installedBrowsers = installedBrowsers
        self.allProfiles = allProfiles
        self.onSave = onSave

        let initialBrowserID = rule?.browserID ?? installedBrowsers.first?.id ?? "chrome"
        let browserProfiles = allProfiles.filter { $0.browserID == initialBrowserID }

        _pattern = State(initialValue: rule?.pattern ?? "")
        _browserID = State(initialValue: initialBrowserID)
        _profileDirectory = State(
            initialValue: rule?.profileDirectory ?? browserProfiles.first?.directory ?? ""
        )
        _isEnabled = State(initialValue: rule?.isEnabled ?? true)
    }

    private var isValidPattern: Bool {
        !pattern.isEmpty && (try? Regex(pattern)) != nil
    }

    private var selectedBrowser: BrowserDefinition? {
        installedBrowsers.first(where: { $0.id == browserID })
    }

    private var browserProfiles: [BrowserProfile] {
        allProfiles.filter { $0.browserID == browserID }
    }

    private var hasProfiles: Bool {
        selectedBrowser?.browserType != .safari
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("URL Pattern (Regex)") {
                    HStack {
                        TextField("e.g. github\\.com", text: $pattern)
                            .font(.system(.body, design: .monospaced))
                            .textFieldStyle(.roundedBorder)

                        if !pattern.isEmpty {
                            Image(systemName: isValidPattern ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isValidPattern ? .green : .red)
                        }
                    }

                    if !pattern.isEmpty && !isValidPattern {
                        Text("Invalid regular expression")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Section("Target Browser") {
                    if installedBrowsers.isEmpty {
                        Text("No browsers found.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Browser", selection: $browserID) {
                            ForEach(installedBrowsers) { browser in
                                Text(browser.name)
                                    .tag(browser.id)
                            }
                        }
                        .onChange(of: browserID) { _, newValue in
                            let profiles = allProfiles.filter { $0.browserID == newValue }
                            profileDirectory = profiles.first?.directory ?? ""
                        }

                        if hasProfiles {
                            if browserProfiles.isEmpty {
                                Text("No profiles found for this browser.")
                                    .foregroundStyle(.secondary)
                            } else {
                                Picker("Profile", selection: $profileDirectory) {
                                    ForEach(browserProfiles) { profile in
                                        Text(profile.displayName)
                                            .tag(profile.directory)
                                    }
                                }
                            }
                        }
                    }
                }

                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .formStyle(.grouped)
            .scrollIndicators(.automatic)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(existingRule == nil ? "Add Rule" : "Save") {
                    let rule = Rule(
                        id: existingRule?.id ?? UUID(),
                        pattern: pattern,
                        browserID: browserID,
                        profileDirectory: profileDirectory,
                        isEnabled: isEnabled
                    )
                    onSave(rule)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValidPattern)
            }
            .padding()
        }
        .frame(minWidth: 450, idealWidth: 450, minHeight: 280, idealHeight: 380)
    }
}
