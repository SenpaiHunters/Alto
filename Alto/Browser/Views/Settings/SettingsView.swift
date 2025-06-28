//
import OpenADK
import SwiftUI
import UniformTypeIdentifiers

// MARK: - SettingsView

// What is needed:

struct SettingsView: View {
    @Bindable var preferences = PreferencesManager.shared
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                // General Settings Tab
                Section("General") {
                    NavigationLink(value: SettingsTab.general) {
                        Label("General", systemImage: "gear")
                    }
                }

                // Privacy & Security Tab
                Section("Privacy & Security") {
                    NavigationLink(value: SettingsTab.privacy) {
                        Label("Privacy & Security", systemImage: "shield")
                    }
                }

                // AdBlock Settings Tab
                Section("AdBlock") {
                    NavigationLink(value: SettingsTab.adBlock) {
                        Label("AdBlock", systemImage: "shield.lefthalf.filled")
                    }
                }

                // Downloads Settings Tab
                Section("Downloads") {
                    NavigationLink(value: SettingsTab.downloads) {
                        Label("Downloads", systemImage: "arrow.down.circle")
                    }
                }

                // Features Tab
                Section("Features") {
                    NavigationLink(value: SettingsTab.extensions) {
                        Label("Extensions", systemImage: "puzzlepiece.extension")
                    }
                }
            }
            .navigationTitle("Settings")
        } detail: {
            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView(preferences: preferences)
                        .navigationTitle("General")
                case .privacy:
                    PrivacySettingsView(preferences: preferences)
                        .navigationTitle("Privacy & Security")
                case .adBlock:
                    AdBlockSettingsView()
                        .navigationTitle("AdBlock")
                case .downloads:
                    DownloadsSettingsView(preferences: preferences)
                        .navigationTitle("Downloads")
                case .extensions:
                    ExtensionSettingsView()
                        .navigationTitle("Extensions")
                }
            }
            .frame(minWidth: 500, minHeight: 400)
        }
        .frame(minWidth: 600, minHeight: 500)
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
    }
}

// MARK: - GeneralSettingsView

struct GeneralSettingsView: View {
    @Bindable var preferences: PreferencesManager

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $preferences.storedColorScheme) {
                    Label("Light", systemImage: "sun.max").tag("light")
                    Label("Dark", systemImage: "moon").tag("dark")
                    Label("System", systemImage: "gear").tag("system")
                }
                .pickerStyle(.menu)

                Picker("Sidebar Position", selection: $preferences.storedSidebarPosition) {
                    Label("Top (Horizontal)", systemImage: "rectangle.grid.1x2").tag("top")
                    Label("Left Sidebar", systemImage: "sidebar.left").tag("left")
                    // TODO: Fix the right sidebar's design
                    // Label("Right Sidebar", systemImage: "sidebar.right").tag("right")
                }
                .pickerStyle(.menu)
            }

            Section("Search") {
                Picker("Search Engine", selection: $preferences.storedSearchEngine) {
                    ForEach(SearchManager.popularSearchEngines, id: \.rawValue) { engine in
                        Label(engine.displayName, systemImage: engine.iconName)
                            .tag(engine.rawValue)
                    }
                }
                .pickerStyle(.menu)

                if SearchManager.shared.supportsSuggestions {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Search suggestions enabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                        Text("Search suggestions not supported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(20)
    }
}

// MARK: - PrivacySettingsView

struct PrivacySettingsView: View {
    @Bindable var preferences: PreferencesManager

    var body: some View {
        Form {
            Section("Search History") {
                Button("Clear Search History") {
                    SearchManager.shared.clearHistory()
                }
                .foregroundColor(.red)

                Text("Recent searches: \(SearchManager.shared.getRecentSearches().count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
    }
}

// MARK: - DownloadsSettingsView

struct DownloadsSettingsView: View {
    @Bindable var preferences: PreferencesManager
    @State private var showingFolderPicker = false

    var body: some View {
        Form {
            Section("Download Location") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Download files to:")
                            .font(.callout)

                        Text(preferences.downloadPath.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    Button("Choose...") {
                        showingFolderPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)

                Button("Open Downloads Folder") {
                    NSWorkspace.shared.open(preferences.downloadPath)
                }
                .buttonStyle(.link)
            }

//            Section("Download Indicator") {
//                Toggle("Show download progress in top bar", isOn: $preferences.showDownloadProgress)
//
//                Text("When enabled, a circular progress indicator will appear around the download button showing
//                active download progress.")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }

            Section("Download History") {
                HStack {
                    Text("Downloads are saved to Application Support for privacy")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Clear History") {
                        clearDownloadHistory()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                if let selectedURL = urls.first {
                    // Request access to the selected folder
                    _ = selectedURL.startAccessingSecurityScopedResource()
                    defer { selectedURL.stopAccessingSecurityScopedResource() }

                    preferences.storedDownloadPath = selectedURL.path
                }
            case let .failure(error):
                print("Error selecting folder: \(error)")
            }
        }
    }

    private func clearDownloadHistory() {
        // Clear download history from DownloadManager
        DownloadManager.shared.clearCompleted()

        // Also clear the metadata file
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let settingsDir = appSupportDir.appendingPathComponent("Alto/Downloads")
        let metadataFile = settingsDir.appendingPathComponent("downloads_metadata.json")

        try? fileManager.removeItem(at: metadataFile)
    }
}

// MARK: - SettingsTab

// Implementation is in separate ExtensionSettingsView.swift file

// #Preview {
//    SettingsView()
// }

enum SettingsTab: String, CaseIterable {
    case general
    case privacy
    case adBlock
    case downloads
    case extensions
}
