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
                profiles: state.profiles,
                onSave: { updated in state.updateRule(updated) }
            )
        }
    }
}

private struct RuleRow: View {
    let rule: Rule
    let index: Int
    let profiles: [ChromeProfile]

    private var profileName: String {
        profiles.first(where: { $0.directory == rule.profileDirectory })?.displayName
            ?? rule.profileDirectory
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rule.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(rule.isEnabled ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.pattern)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(rule.isValidPattern ? Color.primary : Color.red)

                Text(profileName)
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
