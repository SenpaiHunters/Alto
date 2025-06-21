import SwiftUI

// MARK: - AltoApp

@main
struct AltoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var altoState = AltoState()

    var body: some Scene {
        // No default window
        Settings {
            SettingsView()
                .environment(altoState)
        }
        .commands {
            ExtensionsCommands(altoState: altoState)
        }
    }
}

// MARK: - ExtensionsCommands

// Extensions menu for macOS menu bar
struct ExtensionsCommands: Commands {
    let altoState: AltoState

    var body: some Commands {
        CommandMenu("Extensions") {
            if altoState.loadedExtensions.isEmpty {
                Button("No Extensions Installed") {}
                    .disabled(true)
            } else {
                ForEach(
                    altoState.loadedExtensions.sorted(by: { $0.manifest.name < $1.manifest.name }),
                    id: \.id
                ) { webExtension in
                    Button(webExtension.manifest.name) {
                        // Load the extension's HTML content properly
                        ExtensionWindowManager.shared.openExtensionPopup(webExtension)
                    }
                }

                Divider()
            }

            Button("Manage Extensions...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])
        }
    }
}
