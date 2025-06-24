//
//  ABManager.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation
import OSLog
import WebKit

// MARK: - ABManager

/// Main manager for AltoBlock ad blocking functionality
@MainActor
public class ABManager: ObservableObject {
    public static let shared = ABManager()

    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABManager")

    // MARK: - Published Properties

    @Published public var isEnabled = true
    @Published public var totalBlockedRequests = 0
    @Published public var blockedRequestsThisSession = 0
    @Published public var whitelistedDomains: Set<String> = []

    // MARK: - Core Components

    public let contentBlocker = ABContentBlocker()
    public let filterListManager = ABFilterListManager()
    public let statisticsManager = ABStatistics()

    // MARK: - WebKit Content Rule List

    private var compiledRuleList: WKContentRuleList?

    // MARK: - Initialization State

    private var isInitialized = false
    private var initializationTask: Task<(), Never>?

    // File-based storage
    private let settingsURL: URL

    private init() {
        // Setup file-based storage for settings
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let adBlockDir = appSupportDir.appendingPathComponent("Alto/AdBlock")
        settingsURL = adBlockDir.appendingPathComponent("Settings.json")

        // Create directory if needed
        try? fileManager.createDirectory(at: adBlockDir, withIntermediateDirectories: true)

        logger.info("🛡️ ABManager initializing...")

        // Clear old UserDefaults and migrate to file storage
        clearLegacyUserDefaults()
        loadSettings()

        // Don't start rule compilation automatically - wait for explicit initialization
        logger.info("🛡️ ABManager basic setup complete, waiting for explicit initialization")
    }

    // MARK: - Public Interface

    /// Initialize content blocking system
    public func initializeContentBlocking() async {
        // Prevent duplicate initialization
        if isInitialized {
            logger.info("⏭️ Content blocking already initialized, skipping")
            return
        }

        // If there's already an initialization task running, wait for it
        if let existingTask = initializationTask {
            logger.info("⏳ Content blocking initialization already in progress, waiting...")
            await existingTask.value
            return
        }

        // Start new initialization task
        initializationTask = Task {
            await performInitialization()
        }

        await initializationTask?.value
    }

    private func performInitialization() async {
        guard !isInitialized else { return }

        logger.info("🛡️ Initializing content blocking system...")

        do {
            // Filter lists are loaded during ABFilterListManager initialization

            // Compile rules
            await compileContentRules()

            isInitialized = true
            logger.info("✅ Content blocking system initialized successfully")
        } catch {
            logger.error("❌ Failed to initialize content blocking: \(error)")
        }

        initializationTask = nil
    }

    /// Apply content blocking to a WebView
    public func applyContentBlocking(to webView: WKWebView) async {
        let webViewURL = webView.url?.absoluteString ?? "no URL"

        guard isEnabled, let ruleList = compiledRuleList else {
            logger.info("⏭️ Content blocking disabled or no rules compiled for WebView: \(webViewURL)")
            return
        }

        logger.info("🛡️ Applying content blocking to WebView: \(webViewURL)")

        // Remove existing rules first
        await webView.configuration.userContentController.removeAllContentRuleLists()
        logger.debug("🗑️ Removed existing content rules from WebView")

        // Add new rules
        await webView.configuration.userContentController.add(ruleList)
        logger.info("✅ Added new content rules to WebView: \(webViewURL)")

        // Register for navigation events to track blocked requests
        contentBlocker.registerWebView(webView)
        logger.debug("📝 Registered WebView for statistics tracking: \(webViewURL)")
    }

    /// Remove content blocking from a WebView
    public func removeContentBlocking(from webView: WKWebView) async {
        logger.debug("🚫 Removing content blocking from WebView")

        await webView.configuration.userContentController.removeAllContentRuleLists()

        contentBlocker.unregisterWebView(webView)
    }

    /// Toggle ad blocking on/off
    public func toggleAdBlocking() {
        isEnabled.toggle()
        saveSettings()

        if isEnabled {
            Task {
                await contentBlocker.enableForAllWebViews()
            }
        } else {
            Task {
                await contentBlocker.disableForAllWebViews()
            }
        }

        logger.info("🔄 Ad blocking toggled: \(isEnabled ? "ON" : "OFF")")

        // Trigger UI update
        objectWillChange.send()
    }

    /// Check if a domain is whitelisted
    public func isDomainWhitelisted(_ domain: String) -> Bool {
        whitelistedDomains.contains(domain.lowercased())
    }

    /// Add domain to whitelist
    public func addToWhitelist(domain: String) {
        let cleanDomain = domain.lowercased().replacingOccurrences(of: "www.", with: "")
        whitelistedDomains.insert(cleanDomain)
        saveSettings()

        Task {
            await contentBlocker.compileAndApplyRules()
        }

        logger.info("✅ Added \(cleanDomain) to whitelist")

        // Trigger UI update
        objectWillChange.send()
    }

    /// Remove domain from whitelist
    public func removeFromWhitelist(domain: String) {
        let cleanDomain = domain.lowercased().replacingOccurrences(of: "www.", with: "")
        whitelistedDomains.remove(cleanDomain)
        saveSettings()

        Task {
            await contentBlocker.compileAndApplyRules()
        }

        logger.info("🗑️ Removed \(cleanDomain) from whitelist")

        // Trigger UI update
        objectWillChange.send()
    }

    /// Get blocking statistics for the current page
    public func getPageStatistics(for url: URL) -> ABPageStats {
        statisticsManager.getPageStats(for: url)
    }

    /// Get global blocking statistics
    public func getGlobalStatistics() -> ABGlobalStats {
        statisticsManager.getGlobalStats()
    }

    /// Update filter lists
    public func updateFilterLists() async {
        logger.info("🔄 Updating filter lists...")

        do {
            await filterListManager.updateAllFilterLists()
            await contentBlocker.compileAndApplyRules()
            logger.info("✅ Filter lists updated successfully")
        } catch {
            logger.error("❌ Failed to update filter lists: \(error)")
        }
    }

    /// Get the current compiled rule list for immediate application to WebViews
    public func getCurrentCompiledRuleList() async -> WKContentRuleList? {
        compiledRuleList
    }

    /// Set the compiled rule list (used by ABContentBlocker to keep in sync)
    public func setCompiledRuleList(_ ruleList: WKContentRuleList) async {
        compiledRuleList = ruleList
    }

    // MARK: - Private Methods

    private func compileContentRules() async {
        // Delegate to ABContentBlocker to avoid duplication
        await contentBlocker.compileAndApplyRules()
    }

    // MARK: - Settings Persistence

    private struct ManagerSettings: Codable {
        let isEnabled: Bool
        let totalBlockedRequests: Int
        let blockedRequestsThisSession: Int
        let whitelistedDomains: Set<String>
    }

    private func clearLegacyUserDefaults() {
        // Clear all old UserDefaults keys
        let legacyKeys = [
            "AltoBlock.isEnabled",
            "AltoBlock.totalBlockedRequests",
            "AltoBlock.blockedRequestsThisSession",
            "AltoBlock.whitelistedDomains",
            "AltoBlock.filterLists",
            "AltoBlock.filterListCache"
        ]

        let defaults = UserDefaults.standard
        for key in legacyKeys {
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()

        logger.info("🗑️ Cleared legacy UserDefaults keys for AdBlock")
    }

    private func loadSettings() {
        guard FileManager.default.fileExists(atPath: settingsURL.path) else {
            // Use defaults for fresh install
            isEnabled = true
            totalBlockedRequests = 0
            blockedRequestsThisSession = 0
            whitelistedDomains = []
            saveSettings() // Save defaults to file
            logger.info("📋 Using default settings for fresh install")
            return
        }

        do {
            let data = try Data(contentsOf: settingsURL)
            let settings = try JSONDecoder().decode(ManagerSettings.self, from: data)

            isEnabled = settings.isEnabled
            totalBlockedRequests = settings.totalBlockedRequests
            blockedRequestsThisSession = settings.blockedRequestsThisSession
            whitelistedDomains = settings.whitelistedDomains

            logger
                .info(
                    "📋 Loaded settings from file: enabled=\(isEnabled), blocked=\(totalBlockedRequests), whitelist=\(whitelistedDomains.count)"
                )
        } catch {
            logger.error("❌ Failed to load settings from file: \(error)")
            logger.info("📋 Using default settings")

            // Reset to defaults on load failure
            isEnabled = true
            totalBlockedRequests = 0
            blockedRequestsThisSession = 0
            whitelistedDomains = []
        }
    }

    private func saveSettings() {
        let settings = ManagerSettings(
            isEnabled: isEnabled,
            totalBlockedRequests: totalBlockedRequests,
            blockedRequestsThisSession: blockedRequestsThisSession,
            whitelistedDomains: whitelistedDomains
        )

        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: settingsURL, options: .atomic)
            logger.debug("💾 Saved settings to file")
        } catch {
            logger.error("❌ Failed to save settings to file: \(error)")
        }
    }
}

// MARK: - Statistics Update Interface

extension ABManager {
    /// Called when a request is blocked
    func recordBlockedRequest(url: URL, onPage pageURL: URL) {
        totalBlockedRequests += 1
        blockedRequestsThisSession += 1
        statisticsManager.recordBlockedRequest(url: url, onPage: pageURL)
        saveSettings()

        logger.info("🚫 BLOCKED REQUEST: \(url.absoluteString) on page: \(pageURL.host ?? pageURL.absoluteString)")

        // Log special cases
        if url.host?.contains("youtube") == true || pageURL.host?.contains("youtube") == true {
            logger.warning("🎥 YouTube request blocked: \(url.absoluteString)")
        }

        if url.absoluteString.contains("img") || url.absoluteString.contains("thumb") {
            logger.warning("🖼️ Image/thumbnail request blocked: \(url.absoluteString)")
        }

        // Trigger UI update
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    /// Called when a page loads
    func recordPageLoad(url: URL) {
        statisticsManager.recordPageLoad(url: url)
        logger.info("📄 Page load recorded: \(url.absoluteString)")

        if url.host?.contains("youtube") == true {
            logger.info("🎥 YouTube page load: \(url.absoluteString)")
        }
    }
}
