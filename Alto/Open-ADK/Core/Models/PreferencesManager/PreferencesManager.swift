import Combine
import Observation
import SwiftUI

// MARK: - PreferencesManager

@Observable
final class PreferencesManager {
    static let shared = PreferencesManager()

    // Use instance variable instead of static
    @UserDefault(key: "colorScheme", defaultValue: "dark")
    @ObservationIgnored var storedColorScheme: String

    @UserDefault(key: "searchEngine", defaultValue: "brave")
    @ObservationIgnored var storedSearchEngine: String

    @UserDefault(key: "sidebarPosition", defaultValue: "top")
    @ObservationIgnored var storedSidebarPosition: String

    /// Publicly available and observed version of Preferences
    var colorScheme: ColorScheme?
    var searchEngine: SearchEngine
    var sidebarPosition: SidebarPosition

    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Initialize with default values first
        colorScheme = nil
        searchEngine = .google
        sidebarPosition = .top

        // Then update with actual stored values
        colorScheme = Self.getScheme(from: storedColorScheme)
        searchEngine = Self.getSearchEngine(string: storedSearchEngine)
        sidebarPosition = Self.getSidebarPosition(from: storedSidebarPosition)

        // Now set up the observers
        $storedColorScheme.sink { [weak self] newValue in
            self?.colorScheme = Self.getScheme(from: newValue)
        }
        .store(in: &cancellables)

        $storedSearchEngine.sink { [weak self] newValue in
            self?.searchEngine = Self.getSearchEngine(string: newValue)
        }
        .store(in: &cancellables)

        $storedSidebarPosition.sink { [weak self] newValue in
            self?.sidebarPosition = Self.getSidebarPosition(from: newValue)
        }
        .store(in: &cancellables)
    }

    // Make these static methods so they can be called during initialization
    static func getScheme(from string: String) -> ColorScheme? {
        switch string {
        case "dark": .dark
        case "light": .light
        default: nil
        }
    }

    static func getSearchEngine(string: String) -> SearchEngine {
        switch string {
        case "google": .google
        case "duckduckgo": .duckduckgo
        case "brave": .brave
        case "bing": .bing
        case "yahoo": .yahoo
        case "startpage": .startpage
        case "searx": .searx
        case "none": .none
        default: .google
        }
    }

    static func getSidebarPosition(from string: String) -> SidebarPosition {
        switch string {
        case "left": .left
        case "right": .right
        case "top": .top
        default: .top
        }
    }

    // Method to update search engine and persist it
    func setSearchEngine(_ engine: SearchEngine) {
        searchEngine = engine
        storedSearchEngine = engine.rawValue
    }

    // Method to update sidebar position and persist it
    func setSidebarPosition(_ position: SidebarPosition) {
        sidebarPosition = position
        storedSidebarPosition = position.rawValue
    }

    // Method to update color scheme and persist it
    func setColorScheme(_ scheme: ColorScheme?) {
        colorScheme = scheme
        storedColorScheme = scheme?.stringValue ?? "system"
    }
}

// MARK: - SidebarPosition

enum SidebarPosition: String, CaseIterable {
    case top
    case left
    case right
}

// MARK: - ColorScheme Extension

extension ColorScheme {
    var stringValue: String {
        switch self {
        case .dark: return "dark"
        case .light: return "light"
        @unknown default: return "system"
        }
    }
}
