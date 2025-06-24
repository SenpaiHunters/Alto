//
import OpenADK
import SwiftUI

// MARK: - SettingsView

// What is needed:

struct SettingsView: View {
    @Bindable var preferences = PreferencesManager.shared

    var body: some View {
        TabView {
            // General Settings Tab
            GeneralSettingsView(preferences: preferences)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            // Privacy & Security Tab
            PrivacySettingsView(preferences: preferences)
                .tabItem {
                    Label("Privacy & Security", systemImage: "shield")
                }

            // AdBlock Settings Tab
            AdBlockSettingsView()
                .tabItem {
                    Label("AdBlock", systemImage: "shield.lefthalf.filled")
                }
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

// #Preview {
//    SettingsView()
// }
