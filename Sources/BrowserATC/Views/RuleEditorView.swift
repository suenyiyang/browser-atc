import SwiftUI

struct RuleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var pattern: String
    @State private var profileDirectory: String
    @State private var isEnabled: Bool

    private let existingRule: Rule?
    private let profiles: [ChromeProfile]
    private let onSave: (Rule) -> Void

    init(rule: Rule? = nil, profiles: [ChromeProfile], onSave: @escaping (Rule) -> Void) {
        self.existingRule = rule
        self.profiles = profiles
        self.onSave = onSave
        _pattern = State(initialValue: rule?.pattern ?? "")
        _profileDirectory = State(initialValue: rule?.profileDirectory ?? profiles.first?.directory ?? "Default")
        _isEnabled = State(initialValue: rule?.isEnabled ?? true)
    }

    private var isValidPattern: Bool {
        !pattern.isEmpty && (try? Regex(pattern)) != nil
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

                Section("Chrome Profile") {
                    if profiles.isEmpty {
                        Text("No Chrome profiles found. Make sure Chrome is installed.")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Profile", selection: $profileDirectory) {
                            ForEach(profiles) { profile in
                                Text(profile.displayName)
                                    .tag(profile.directory)
                            }
                        }
                    }
                }

                Section {
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(existingRule == nil ? "Add Rule" : "Save") {
                    let rule = Rule(
                        id: existingRule?.id ?? UUID(),
                        pattern: pattern,
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
        .frame(width: 450, height: 320)
    }
}
