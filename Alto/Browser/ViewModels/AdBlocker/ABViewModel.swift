//
//  ABViewModel.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation
import OSLog
import SwiftUI

/// ViewModel for AltoBlock UI interactions
@MainActor
@Observable
public class ABViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABViewModel")

    // MARK: - Dependencies

    private let abManager = ABManager.shared

    // MARK: - Published Properties

    public var isEnabled: Bool {
        get { abManager.isEnabled }
        set {
            if newValue != abManager.isEnabled {
                abManager.toggleAdBlocking()
            }
        }
    }

    public var totalBlockedRequests: Int { abManager.totalBlockedRequests }
    public var blockedRequestsThisSession: Int { abManager.blockedRequestsThisSession }
    public var whitelistedDomains: Set<String> { abManager.whitelistedDomains }

    // UI State
    public var isShowingAddFilterSheet = false
    public var isShowingWhitelistSheet = false
    public var isShowingStatistics = false

    // Form fields
    public var newFilterListName = ""
    public var newFilterListURL = ""
    public var newWhitelistDomain = ""

    // Statistics
    public var globalStats: ABGlobalStats { abManager.getGlobalStatistics() }

    // MARK: - Filter List Management

    /// Get all available filter lists
    public var filterLists: [ABFilterList] {
        abManager.filterListManager.availableFilterLists
    }

    /// Check if filter lists are currently updating
    public var isUpdatingFilters: Bool {
        abManager.filterListManager.isUpdating
    }

    // MARK: - Actions

    /// Toggle a filter list on/off
    public func toggleFilterList(_ filterList: ABFilterList) {
        abManager.filterListManager.toggleFilterList(filterList)
        logger.info("🔄 Toggled filter list: \(filterList.name)")

        // Trigger UI update immediately
        objectWillChange.send()

        // Recompile rules in background
        Task {
            await abManager.contentBlocker.compileAndApplyRules()
        }
    }

    /// Add a new custom filter list
    public func addCustomFilterList() {
        guard !newFilterListName.isEmpty, !newFilterListURL.isEmpty else {
            logger.warning("⚠️ Cannot add filter list with empty name or URL")
            return
        }

        guard URL(string: newFilterListURL) != nil else {
            logger.warning("⚠️ Invalid URL for filter list")
            return
        }

        let listName = newFilterListName // Capture before reset

        abManager.filterListManager.addCustomFilterList(
            name: newFilterListName,
            url: newFilterListURL
        )

        // Reset form
        newFilterListName = ""
        newFilterListURL = ""
        isShowingAddFilterSheet = false

        logger.info("➕ Added custom filter list: \(listName)")

        // Trigger UI update immediately
        objectWillChange.send()

        // Recompile rules in background
        Task {
            await abManager.contentBlocker.compileAndApplyRules()
        }
    }

    /// Remove a filter list
    public func removeFilterList(_ filterList: ABFilterList) {
        abManager.filterListManager.removeFilterList(filterList)
        logger.info("🗑️ Removed filter list: \(filterList.name)")

        // Trigger UI update immediately
        objectWillChange.send()

        // Recompile rules in background
        Task {
            await abManager.contentBlocker.compileAndApplyRules()
        }
    }

    /// Update all filter lists
    public func updateAllFilterLists() {
        Task {
            await abManager.updateFilterLists()
            logger.info("🔄 Updated all filter lists")
        }
    }

    // MARK: - Whitelist Management

    /// Add domain to whitelist
    public func addToWhitelist() {
        guard !newWhitelistDomain.isEmpty else {
            logger.warning("⚠️ Cannot add empty domain to whitelist")
            return
        }

        abManager.addToWhitelist(domain: newWhitelistDomain)

        // Reset form
        newWhitelistDomain = ""
        isShowingWhitelistSheet = false

        logger.info("✅ Added domain to whitelist")

        // Trigger UI update (ABManager already handles this but ensure ViewModel updates too)
        objectWillChange.send()
    }

    /// Remove domain from whitelist
    public func removeFromWhitelist(_ domain: String) {
        abManager.removeFromWhitelist(domain: domain)
        logger.info("🗑️ Removed domain from whitelist: \(domain)")

        // Trigger UI update (ABManager already handles this but ensure ViewModel updates too)
        objectWillChange.send()
    }

    /// Check if a domain is whitelisted
    public func isDomainWhitelisted(_ domain: String) -> Bool {
        abManager.isDomainWhitelisted(domain)
    }

    // MARK: - Statistics

    /// Get formatted global statistics
    public var formattedGlobalStats: String {
        let stats = globalStats
        return """
        🛡️ Blocked: \(stats.totalBlockedRequests.formatted())
        📊 Total: \(stats.totalRequests.formatted())
        📈 Percentage: \(stats.formattedBlockingPercentage)
        💾 Saved: \(stats.formattedBandwidthSaved)
        ⏱️ Session: \(stats.formattedSessionDuration)
        """
    }

    /// Get page statistics for current page
    public func getPageStats(for url: URL) -> ABPageStats {
        abManager.getPageStatistics(for: url)
    }

    /// Get top blocked domains
    public func getTopBlockedDomains() -> [(domain: String, count: Int)] {
        abManager.statisticsManager.getTopBlockedDomains()
    }

    /// Reset all statistics
    public func resetStatistics() {
        abManager.statisticsManager.resetAllStats()
        logger.info("🔄 Reset all statistics")
    }

    // MARK: - Validation Helpers

    /// Validate filter list URL
    public func validateFilterListURL(_ url: String) -> Bool {
        guard let validURL = URL(string: url) else { return false }
        return validURL.scheme == "https" || validURL.scheme == "http"
    }

    /// Validate domain for whitelist
    public func validateDomain(_ domain: String) -> Bool {
        let cleanDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanDomain.isEmpty else { return false }

        // Basic domain validation
        let domainRegex =
            #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$"#
        return cleanDomain.range(of: domainRegex, options: .regularExpression) != nil
    }

    // MARK: - Helper Methods

    /// Get filter lists grouped by category
    public var filterListsByCategory: [(category: ABFilterCategory, lists: [ABFilterList])] {
        let categories = ABFilterCategory.allCases
        return categories.compactMap { category in
            let listsInCategory = filterLists.filter { $0.category == category }
            return listsInCategory.isEmpty ? nil : (category: category, lists: listsInCategory)
        }
    }

    /// Get summary of active filters
    public var activeFiltersSummary: String {
        let activeCount = filterLists.filter(\.isEnabled).count
        let totalCount = filterLists.count
        return "\(activeCount)/\(totalCount) filter lists active"
    }

    /// Get sorted whitelisted domains
    public var sortedWhitelistedDomains: [String] {
        Array(whitelistedDomains).sorted()
    }

    /// Check if a new filter list can be added
    public var canAddFilterList: Bool {
        !newFilterListName.isEmpty &&
            !newFilterListURL.isEmpty &&
            validateFilterListURL(newFilterListURL)
    }

    /// Check if a new whitelist domain can be added
    public var canAddWhitelistDomain: Bool {
        !newWhitelistDomain.isEmpty &&
            validateDomain(newWhitelistDomain)
    }

    /// Export current statistics as JSON
    public func exportStatistics() -> String? {
        let stats = globalStats
        let exportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "totalBlockedRequests": stats.totalBlockedRequests,
            "totalRequests": stats.totalRequests,
            "blockingPercentage": stats.blockingPercentage,
            "bandwidthSaved": stats.bandwidthSaved,
            "sessionDuration": stats.sessionDuration,
            "topBlockedDomains": getTopBlockedDomains().map { ["domain": $0.domain, "count": $0.count] },
            "activeFilterLists": filterLists.filter(\.isEnabled).map { ["name": $0.name, "url": $0.url] },
            "whitelistedDomains": Array(whitelistedDomains)
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return jsonString
    }

    // MARK: - Initialization

    public init() {
        logger.info("🛡️ ABViewModel initialized")
    }
}
