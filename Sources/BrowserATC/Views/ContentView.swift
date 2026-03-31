import SwiftUI

struct ContentView: View {
    @Bindable var state: AppState
    @State private var showingAddSheet = false
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Text("\(state.profiles.count) profiles detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        state.refreshProfiles()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .help("Refresh Chrome profiles")

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .help("Settings")

                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("Add rule")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Group {
                if state.rules.isEmpty {
                    ContentUnavailableView(
                        "No Rules",
                        systemImage: "airplane.circle",
                        description: Text("Add rules to route URLs to specific Chrome profiles.")
                    )
                } else {
                    RuleListView(state: state)
                }
            }
        }
        .navigationTitle("Browser ATC")
        .sheet(isPresented: $showingAddSheet) {
            RuleEditorView(
                profiles: state.profiles,
                onSave: { rule in state.addRule(rule) }
            )
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(state: state)
        }
        .frame(minWidth: 500, minHeight: 300)
    }
}
