import SwiftUI
import SwiftData
import AppKit
import KafeelCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]

    private var appSettings: AppSettings? {
        settings.first
    }

    var body: some View {
        NavigationStack {
            Form {
                startupSection
                appearanceSection
                trackingSection
                categorySection
                workspaceSection
                gitRepositoriesSection
                dataSection
                aboutSection
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .frame(minWidth: 500, minHeight: 400)
        }
    }

    private var startupSection: some View {
        Section("Startup") {
            Toggle(isOn: Binding(
                get: { LaunchAtLogin.isEnabled },
                set: { LaunchAtLogin.isEnabled = $0 }
            )) {
                VStack(alignment: .leading) {
                    Text("Launch at Login")
                        .font(.headline)
                    Text("Automatically start Kafeel when you log in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if LaunchAtLogin.status == .requiresApproval {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Requires approval in System Settings > General > Login Items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            if let settings = appSettings {
                Toggle(isOn: Binding(
                    get: { settings.showInDock },
                    set: { newValue in
                        settings.showInDock = newValue
                        updateDockVisibility(show: newValue)
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text("Show in Dock")
                            .font(.headline)
                        Text("Display app icon in the Dock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Toggle(isOn: Binding(
                    get: { settings.showInMenuBar },
                    set: { settings.showInMenuBar = $0 }
                )) {
                    VStack(alignment: .leading) {
                        Text("Show in Menu Bar")
                            .font(.headline)
                        Text("Display status icon in the menu bar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Picker("Menu Bar Click Action", selection: Binding(
                    get: { settings.menuBarClickBehavior },
                    set: { settings.menuBarClickBehavior = $0 }
                )) {
                    Text("Show Quick View").tag(MenuBarClickBehavior.showPopover)
                    Text("Open Main Window").tag(MenuBarClickBehavior.openApp)
                }
                .disabled(!settings.showInMenuBar)

                if !settings.showInDock && !settings.showInMenuBar {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("At least one visibility option must be enabled")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func updateDockVisibility(show: Bool) {
        let policy: NSApplication.ActivationPolicy = show ? .regular : .accessory
        NSApplication.shared.setActivationPolicy(policy)
    }

    private var trackingSection: some View {
        Section("Activity Tracking") {
            if let settings = appSettings {
                Toggle(isOn: Binding(
                    get: { settings.isTrackingEnabled },
                    set: { newValue in
                        if newValue {
                            settings.resumeTracking()
                        } else {
                            settings.pauseTracking()
                        }
                    }
                )) {
                    VStack(alignment: .leading) {
                        Text("Enable Tracking")
                            .font(.headline)
                        if !settings.isTrackingEnabled, let pausedTime = settings.lastPausedTime {
                            Text("Paused since \(pausedTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("Loading settings...")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var categorySection: some View {
        Section("Categories") {
            NavigationLink {
                CategoryManagerView()
            } label: {
                Label("Manage App Categories", systemImage: "folder.badge.gearshape")
            }

            if let settings = appSettings {
                Picker("Default Category for New Apps", selection: Binding(
                    get: { settings.defaultCategoryForNewApps },
                    set: { settings.defaultCategoryForNewApps = $0 }
                )) {
                    ForEach(CategoryType.allCases, id: \.self) { category in
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 12, height: 12)
                            Text(category.displayName)
                        }
                        .tag(category)
                    }
                }
            }
        }
    }

    private var workspaceSection: some View {
        Section("Workspace Configuration") {
            if let settings = appSettings {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Main Workspace Folder")
                        .font(.headline)

                    HStack {
                        TextField("e.g., /Users/username/workspace", text: Binding(
                            get: { settings.workspacePath ?? "" },
                            set: { settings.workspacePath = $0.isEmpty ? nil : $0 }
                        ))
                        .textFieldStyle(.roundedBorder)

                        Button {
                            selectWorkspaceFolder()
                        } label: {
                            Text("Browse")
                        }
                    }

                    if let workspacePath = settings.workspacePath {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Workspace: \(workspacePath)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("No workspace folder set. Git scanning will use default locations.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Divider()

                Toggle(isOn: Binding(
                    get: { settings.autoScanEnabled },
                    set: { settings.autoScanEnabled = $0 }
                )) {
                    VStack(alignment: .leading) {
                        Text("Auto-Scan Git Repositories")
                            .font(.headline)
                        if settings.autoScanEnabled {
                            Text("Scanning every \(settings.gitScanFrequencyHours) hour(s)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if let lastScanTime = settings.lastGitScanTime {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(.secondary)
                        Text("Last scan: \(lastScanTime.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func selectWorkspaceFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Choose your main workspace folder"
        panel.prompt = "Select"

        if panel.runModal() == .OK, let url = panel.url {
            if let settings = appSettings {
                settings.workspacePath = url.path
            }
        }
    }

    private var dataSection: some View {
        Section("Data Management") {
            NavigationLink {
                DataManagementView()
            } label: {
                Label("Export & Delete Data", systemImage: "externaldrive.badge.questionmark")
            }
        }
    }

    private var gitRepositoriesSection: some View {
        Section("Git Repositories") {
            if let settings = appSettings {
                ForEach(settings.watchedRepositories, id: \.self) { repo in
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.secondary)
                        Text(repo)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                        Spacer()
                        Button {
                            settings.watchedRepositories.removeAll { $0 == repo }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    addRepository()
                } label: {
                    Label("Add Repository", systemImage: "plus.circle.fill")
                }

                Picker("Scan Frequency", selection: Binding(
                    get: { settings.gitScanFrequencyHours },
                    set: { settings.gitScanFrequencyHours = $0 }
                )) {
                    Text("Every hour").tag(1)
                    Text("Every 6 hours").tag(6)
                    Text("Every 12 hours").tag(12)
                    Text("Daily").tag(24)
                    Text("Manual only").tag(0)
                }
            }
        }
    }

    private func addRepository() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Choose a Git repository directory"

        if panel.runModal() == .OK, let url = panel.url {
            let path = url.path
            if let settings = appSettings, !settings.watchedRepositories.contains(path) {
                settings.watchedRepositories.append(path)
            }
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("Build", value: "1")
            Link(destination: URL(string: "https://github.com")!) {
                Label("GitHub Repository", systemImage: "link")
            }
        }
    }
}
