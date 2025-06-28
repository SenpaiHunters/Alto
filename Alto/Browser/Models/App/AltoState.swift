//
import Combine
import Foundation
import Observation
import OpenADK
import OSLog

// MARK: - ExtensionInstallationState

/// Extension installation state
public enum ExtensionInstallationState {
    case idle
    case installing
    case installed(String) // Extension ID
    case failed(Error)
}

// MARK: - AltoState

/// Main application state for Alto browser
@MainActor
@Observable
public final class AltoState: ADKState, ObservableObject {
    public static let shared = AltoState()

    private let logger = Logger(subsystem: "com.alto.browser", category: "AltoState")

    var sidebar = true
    var sidebarIsRight = false
    // The Command Palette needs to be visible on startup due to the Browser Spec
    var isShowingCommandPalette = true
    var Topbar: AltoTopBarViewModel.TopbarState = .hidden
    var draggedTab: TabRepresentation?

    /// Extension runtime for managing browser extensions
    public let extensionRuntime = ExtensionRuntime.shared

    /// Whether extension support is enabled
    public var extensionSupportEnabled = true

    /// Extension installation prompt state
    public var showExtensionInstallPrompt = false
    public var pendingExtensionURL: URL?
    public var extensionInstallationState: ExtensionInstallationState = .idle

    public init() {
        let altoManager = AltoTabsManager()
        altoManager.currentSpace = AltoData.shared.spaces[0]

        super.init(tabManager: altoManager)

        // Initialize extension system if enabled
        if extensionSupportEnabled {
            initializeExtensionSupport()
        }
    }

    func toggleTopbar() {
        switch Topbar {
        case .hidden:
            Topbar = .active
        case .active:
            Topbar = .hidden
        }
    }

    /// Initialize extension support
    private func initializeExtensionSupport() {
        // Extension runtime is automatically initialized as a singleton
        // Setup extension event listeners
        setupExtensionEventListeners()

        print("🔌 Alto extension support initialized")
    }

    /// Setup extension event listeners
    private func setupExtensionEventListeners() {
        // Listen for extension installation events
        NotificationCenter.default.addObserver(
            forName: .extensionInstalled,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let extensionId = notification.userInfo?["extensionId"] as? UUID else { return }
            self?.handleExtensionInstalled(extensionId)
        }

        // Listen for extension removal events
        NotificationCenter.default.addObserver(
            forName: .extensionRemoved,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let extensionId = notification.userInfo?["extensionId"] as? UUID else { return }
            self?.handleExtensionRemoved(extensionId)
        }

        // Listen for WebView navigation events
        NotificationCenter.default.addObserver(
            forName: .webViewDidFinishNavigation,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let url = notification.userInfo?["url"] as? URL else { return }
            _ = self?.handleSpecialURL(url)
        }

        // Listen for extension settings open requests from BackgroundScriptRunner
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenExtensionSettings"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let extensionId = notification.userInfo?["extensionId"] as? String else { return }

            // Skip if this is marked as handled by runtime - ExtensionRuntime will handle it
            if notification.userInfo?["handledByRuntime"] as? Bool == true {
                print("🔄 Skipping OpenExtensionSettings - will be handled by ExtensionRuntime")
                return
            }

            // Check for duplicate calls using the same key pattern as other components
            let currentTime = Date().timeIntervalSince1970
            let deduplicationKey = "openExtensionSettings_\(extensionId)"

            if let lastCallTime = UserDefaults.standard.object(forKey: deduplicationKey) as? TimeInterval,
               currentTime - lastCallTime < 1.0 {
                print("🔄 Skipping duplicate openExtensionSettings call from AltoState for \(extensionId)")
                return
            }

            UserDefaults.standard.set(currentTime, forKey: deduplicationKey)

            self?.openExtensionSettings(extensionId: extensionId)
        }

        // Listen for extension options page requests from ExtensionRuntime only
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("OpenExtensionOptionsPage"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let extensionId = userInfo["extensionId"] as? String,
                  let optionsPageURL = userInfo["optionsPageURL"] as? URL,
                  let openInTab = userInfo["openInTab"] as? Bool else { return }

            // Only handle notifications from ExtensionRuntime to prevent duplicates
            let source = userInfo["source"] as? String
            guard source == "extension-runtime" else {
                print(
                    "🔄 Skipping OpenExtensionOptionsPage - not from extension-runtime (source: \(source ?? "unknown"))"
                )
                return
            }

            self?.handleOpenExtensionOptionsPage(
                extensionId: extensionId,
                optionsPageURL: optionsPageURL,
                openInTab: openInTab,
                notification: notification
            )
        }
    }

    /// Handle extension installed
    /// - Parameter extensionId: Installed extension ID
    private func handleExtensionInstalled(_ extensionId: UUID) {
        print("✅ Extension installed: \(extensionId)")
        // Update UI, refresh extension list, etc.
    }

    /// Handle extension removed
    /// - Parameter extensionId: Removed extension ID
    private func handleExtensionRemoved(_ extensionId: UUID) {
        print("🗑️ Extension removed: \(extensionId)")
        // Update UI, refresh extension list, etc.
    }

    // MARK: - Extension Management Methods

    /// Install an extension
    public func installExtension(from url: URL) async throws -> String {
        try await extensionRuntime.installExtension(from: url)
    }

    /// Uninstall an extension
    public func uninstallExtension(_ extensionId: String) {
        extensionRuntime.uninstallExtension(extensionId)
    }

    /// Enable/disable an extension
    public func setExtensionEnabled(_ extensionId: String, enabled: Bool) {
        extensionRuntime.setExtensionEnabled(extensionId, enabled: enabled)
    }

    /// Get loaded extensions
    public var loadedExtensions: [String: LoadedExtension] {
        extensionRuntime.loadedExtensions
    }

    // MARK: - URL Handling

    /// Handle special URLs like extension installation
    /// - Parameter url: URL to handle
    /// - Returns: True if URL was handled, false if normal navigation should continue
    public func handleSpecialURL(_ url: URL) -> Bool {
        // Handle Chrome Web Store extension URLs
        if isExtensionInstallURL(url) {
            handleExtensionInstallation(from: url)
            return true
        }

        return false
    }

    /// Check if URL is an extension installation URL
    /// - Parameter url: URL to check
    /// - Returns: True if it's an extension installation URL
    private func isExtensionInstallURL(_ url: URL) -> Bool {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.lowercased()

        print("🔍 Checking extension URL - Host: \(host), Path: \(path)")

        let isExtensionURL = (host.contains("chrome.google.com") || host.contains("chromewebstore.google.com")) &&
            path.contains("detail")

        print("📋 Is extension URL: \(isExtensionURL)")
        return isExtensionURL
    }

    /// Handle extension installation from web store URL
    /// - Parameter url: Web store URL
    private func handleExtensionInstallation(from url: URL) {
        print("🔌 Handling extension installation from: \(url)")

        guard extensionSupportEnabled else {
            print("🚫 Extension support is disabled")
            return
        }

        print("✅ Extension support enabled, showing installation prompt")

        // Show installation prompt to user
        pendingExtensionURL = url
        showExtensionInstallPrompt = true
    }

    /// Confirm and proceed with extension installation
    /// - Parameter url: Extension URL to install
    public func confirmExtensionInstallation(_ url: URL) {
        extensionInstallationState = .installing

        Task {
            do {
                let extensionId = try await extensionRuntime.installExtension(from: url)
                await MainActor.run {
                    extensionInstallationState = .installed(extensionId)
                    print("✅ Extension installed successfully: \(extensionId)")
                }
            } catch {
                await MainActor.run {
                    extensionInstallationState = .failed(error)
                    print("❌ Failed to install extension: \(error)")
                }
            }
        }
    }

    /// Cancel extension installation
    public func cancelExtensionInstallation() {
        showExtensionInstallPrompt = false
        pendingExtensionURL = nil
        extensionInstallationState = .idle
    }

    /// Open extension settings page in a new tab
    /// This is a centralized method for opening extension options pages that can be called
    /// from various parts of the application including chrome.runtime.openOptionsPage() API calls,
    /// Chrome Web Store integration, and the extension settings UI.
    ///
    /// The method supports both manifest v2 (options_page) and v3 (options_ui.page) formats.
    /// - Parameter extensionId: Extension ID to open settings for
    public func openExtensionSettings(extensionId: String) {
        // Check if ExtensionRuntime will handle this (it posts OpenExtensionOptionsPage)
        // If so, skip this method to prevent duplicate tabs
        let currentTime = Date().timeIntervalSince1970
        let deduplicationKey = "openExtensionSettings_\(extensionId)"

        if let lastCallTime = UserDefaults.standard.object(forKey: deduplicationKey) as? TimeInterval,
           currentTime - lastCallTime < 0.5 {
            print("🔄 Skipping openExtensionSettings - ExtensionRuntime will handle via OpenExtensionOptionsPage")
            return
        }

        guard let loadedExtension = extensionRuntime.loadedExtensions[extensionId] else {
            print("❌ Extension not found: \(extensionId)")
            return
        }

        // Check if extension has options page configured
        guard let optionsPage = loadedExtension.manifest.optionsPage ?? loadedExtension.manifest.options?.page else {
            print("❌ Extension \(loadedExtension.manifest.name) has no options page configured")
            return
        }

        // Construct options page URL
        let optionsURL = loadedExtension.url.appendingPathComponent(optionsPage)

        // Verify options page exists
        guard FileManager.default.fileExists(atPath: optionsURL.path) else {
            print("❌ Options page file not found: \(optionsURL.path)")
            return
        }

        print("⚙️ Opening extension settings for \(loadedExtension.manifest.name)")
        print("🔗 Options URL: \(optionsURL)")

        // Create new tab with extension options page
        if let tabManager = tabManager as? AltoTabsManager {
            tabManager.createNewTab(
                url: optionsURL.absoluteString,
                location: "unpinned" // Open in unpinned so it appears in the visible tab list
            )
        }
    }

    /// Handle extension options page opening from ExtensionRuntime
    /// - Parameters:
    ///   - extensionId: The extension ID
    ///   - optionsPageURL: The options page URL
    ///   - openInTab: Whether to open in a new tab
    ///   - notification: The notification containing additional context
    private func handleOpenExtensionOptionsPage(
        extensionId: String,
        optionsPageURL: URL,
        openInTab: Bool,
        notification: Notification
    ) {
        // Add deduplication for tab creation to prevent multiple tabs
        let currentTime = Date().timeIntervalSince1970
        let deduplicationKey = "openExtensionOptionsPage_\(extensionId)"

        if let lastCallTime = UserDefaults.standard.object(forKey: deduplicationKey) as? TimeInterval,
           currentTime - lastCallTime < 1.0 {
            print("🔄 Skipping duplicate openExtensionOptionsPage call for \(extensionId)")
            return
        }

        UserDefaults.standard.set(currentTime, forKey: deduplicationKey)

        guard let loadedExtension = extensionRuntime.loadedExtensions[extensionId] else {
            print("❌ Extension not found: \(extensionId)")
            return
        }

        let isFallback = notification.userInfo?["isFallback"] as? Bool ?? false
        let pageType = isFallback ? "fallback popup" : "options page"

        print("⚙️ Opening extension \(pageType) for \(loadedExtension.manifest.name)")
        print("🔗 \(pageType.capitalized) URL: \(optionsPageURL)")
        print("📑 Open in tab: \(openInTab)")

        // Verify page exists
        guard FileManager.default.fileExists(atPath: optionsPageURL.path) else {
            print("❌ \(pageType.capitalized) file not found: \(optionsPageURL.path)")
            return
        }

        // Create new tab with extension page
        if let tabManager = tabManager as? AltoTabsManager {
            tabManager.createNewTab(
                url: optionsPageURL.absoluteString,
                location: "unpinned" // Open in unpinned so it appears in the visible tab list
            )
        }
    }
}
