//
import Foundation
import Observation
import OpenADK

// MARK: - AltoState

@Observable
@MainActor
class AltoState: GenaricState {
    var sidebar = false
//    The Command Palette needs to be visible on startup due to the Browser Spec
    var isShowingCommandPalette = true
    var Topbar: AltoTopBarViewModel.TopbarState = .active
    var draggedTab: TabRepresentation?

    // Extensions
    var isExtensionsEnabled = true
    var extensionManager = ExtensionManager.shared
    var loadedExtensions: [WebExtension] = []

    func toggleTopbar() {
        switch Topbar {
        case .hidden:
            Topbar = .active
        case .active:
            Topbar = .hidden
        }
    }

    // MARK: - Extension Management

    func loadExtension(from url: URL) async {
        guard isExtensionsEnabled else { return }

        do {
            try await extensionManager.loadExtension(from: url)
            // Refresh loaded extensions list
            loadedExtensions = Array(extensionManager.loadedExtensions.values)
        } catch {
            print("Failed to load extension: \(error)")
        }
    }

    func unloadExtension(id: String) {
        extensionManager.unloadExtension(id: id)
        loadedExtensions = Array(extensionManager.loadedExtensions.values)
    }
}

// MARK: - AltoTab

@Observable
class AltoTab: GenaricTab {}
