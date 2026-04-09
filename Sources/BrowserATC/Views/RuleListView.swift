import SwiftUI

struct RuleListView: View {
    @Bindable var state: AppState
    @State private var editingRule: Rule?

    var body: some View {
        List {
            ForEach(Array(state.rules.enumerated()), id: \.element.id) { index, rule in
                RuleRow(rule: rule, index: index, profiles: state.profiles)
                    .contentShape(Rectangle())
                    .onTapGesture { editingRule = rule }
                    .contextMenu {
                        Button("Edit") { editingRule = rule }
                        Divider()
                        Button("Delete", role: .destructive) {
                            if let idx = state.rules.firstIndex(where: { $0.id == rule.id }) {
                                state.deleteRules(at: IndexSet(integer: idx))
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            if let idx = state.rules.firstIndex(where: { $0.id == rule.id }) {
                                state.deleteRules(at: IndexSet(integer: idx))
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete { offsets in
                state.deleteRules(at: offsets)
            }
            .onMove { source, destination in
                state.moveRules(from: source, to: destination)
            }
        }
        .sheet(item: $editingRule) { rule in
            RuleEditorView(
                rule: rule,
                installedBrowsers: state.installedBrowsers,
                allProfiles: state.profiles,
                onSave: { updated in state.updateRule(updated) }
            )
        }
    }
}

private struct RuleRow: View {
    let rule: Rule
    let index: Int
    let profiles: [BrowserProfile]

    private var browserName: String {
        BrowserDefinition.builtins
            .first(where: { $0.id == rule.browserID })?.name ?? rule.browserID
    }

    private var profileName: String? {
        let profile = profiles.first(where: {
            $0.browserID == rule.browserID && $0.directory == rule.profileDirectory
        })
        guard let name = profile?.displayName, !name.isEmpty, name != browserName else {
            return nil
        }
        return name
    }

    private var targetDescription: String {
        if let profileName {
            return "\(browserName) — \(profileName)"
        }
        return browserName
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(rule.isEnabled ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.pattern)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(rule.isValidPattern ? Color.primary : Color.red)

                Text(targetDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("#\(index + 1)")
                .font(.caption2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}
