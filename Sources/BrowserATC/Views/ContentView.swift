import SwiftUI

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Bindable var state: AppState
    @State private var activeSheet: ActiveSheet?
    @State private var selectedTab = 0
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
            if state.shouldShowUpdateBanner, let release = state.latestRelease {
                UpdateBanner(
                    currentVersion: state.currentVersion,
                    latestVersion: release.version,
                    releaseURL: release.htmlURL,
                    onDismiss: { state.dismissUpdateBanner() }
                )
            }
            TabView(selection: $selectedTab) {
                rulesTab
                    .tabItem { Label("Rules", systemImage: "list.bullet") }
                    .tag(0)

                settingsTab
                    .tabItem { Label("Browsers", systemImage: "globe") }
                    .tag(1)
            }
        }
        .navigationTitle("Browser ATC")
        .toolbarBackground(.hidden, for: .windowToolbar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    state.checkForUpdates(force: true)
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .rotationEffect(.degrees(state.isCheckingForUpdates ? 360 : 0))
                        .animation(
                            state.isCheckingForUpdates
                                ? .linear(duration: 1).repeatForever(autoreverses: false)
                                : .default,
                            value: state.isCheckingForUpdates
                        )
                }
                .disabled(state.isCheckingForUpdates)
                .help("Check for Updates")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    NSWorkspace.shared.open(URL(string: "https://github.com/suenyiyang/browser-atc/issues")!)
                } label: {
                    Image(systemName: "exclamationmark.bubble")
                }
                .help("Send Feedback")
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .add:
                RuleEditorView(
                    installedBrowsers: state.installedBrowsers,
                    allProfiles: state.profiles,
                    onSave: { rule in state.addRule(rule) }
                )
            case .edit(let rule):
                RuleEditorView(
                    rule: rule,
                    installedBrowsers: state.installedBrowsers,
                    allProfiles: state.profiles,
                    onSave: { updated in state.updateRule(updated) }
                )
            }
        }
        .frame(minWidth: 360, idealWidth: 480, maxWidth: 600, minHeight: 300, idealHeight: 450)
        .onAppear {
            WindowManager.openWindow = openWindow
            state.checkForUpdates()
        }
    }

    // MARK: - Rules Tab

    @ViewBuilder
    private var rulesTab: some View {
        VStack(spacing: 0) {
            // Fixed: Test URL
            VStack(alignment: .leading, spacing: 6) {
                Text("Test URL")
                    .font(.headline)
                    .foregroundStyle(.primary)

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
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Fixed: Rules header
            HStack {
                Text("Rule List")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    activeSheet = .add
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add rule")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 2)

            // Scrollable: Rule list
            if state.rules.isEmpty {
                Spacer()
                Text("No rules yet. Click + to add one.")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                List {
                    ForEach(Array(state.rules.enumerated()), id: \.element.id) { index, rule in
                        RuleRow(rule: rule, index: index, profiles: state.profiles)
                            .contentShape(Rectangle())
                            .onTapGesture { activeSheet = .edit(rule) }
                            .contextMenu {
                                Button("Edit") { activeSheet = .edit(rule) }
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
                    .onDelete { offsets in state.deleteRules(at: offsets) }
                    .onMove { source, destination in state.moveRules(from: source, to: destination) }
                }
                .scrollIndicators(.automatic)

                Text("First match wins \u{b7} drag to reorder")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Settings Tab

    @ViewBuilder
    private var settingsTab: some View {
        Form {
            Section {
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
                            Text(browser.name).tag(browser.id)
                        }
                    }

                    if defaultBrowserHasProfiles {
                        if defaultBrowserProfiles.isEmpty {
                            Text("No profiles found.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Fallback Profile", selection: Binding(
                                get: { state.defaultProfileDirectory },
                                set: {
                                    state.defaultProfileDirectory = $0
                                    state.save()
                                }
                            )) {
                                ForEach(defaultBrowserProfiles) { profile in
                                    Text(profile.displayName).tag(profile.directory)
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Default Browser")
                    .font(.headline)
                    .foregroundStyle(.primary)
            } footer: {
                Text("Profile not listed? Go to Browsers & Profiles and refresh.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section {
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

                Button {
                    state.refreshProfiles()
                } label: {
                    Label("Refresh Profiles", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Browsers & Profiles")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.automatic)
    }
}

private enum ActiveSheet: Identifiable {
    case add
    case edit(Rule)

    var id: String {
        switch self {
        case .add: "add"
        case .edit(let rule): rule.id.uuidString
        }
    }
}

private struct UpdateBanner: View {
    let currentVersion: String
    let latestVersion: String
    let releaseURL: URL
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 1) {
                Text("Update available: v\(latestVersion)")
                    .font(.callout.weight(.semibold))
                Text("You're on v\(currentVersion). Run `brew upgrade --cask browser-atc`, or download the new release.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("View Release") {
                NSWorkspace.shared.open(releaseURL)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Dismiss")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.thinMaterial)
        .overlay(Divider(), alignment: .bottom)
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
            return "\(browserName) \u{2014} \(profileName)"
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
        .padding(.vertical, 4)
    }
}
