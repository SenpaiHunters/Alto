//
//  ABModels.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation

// MARK: - ABFilterList

/// Represents a filter list (EasyList, EasyPrivacy, etc.)
public struct ABFilterList: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let url: String
    public let isBuiltIn: Bool
    public var isEnabled: Bool
    public var lastUpdated: Date?

    public init(id: String, name: String, url: String, isBuiltIn: Bool, isEnabled: Bool, lastUpdated: Date? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.isBuiltIn = isBuiltIn
        self.isEnabled = isEnabled
        self.lastUpdated = lastUpdated
    }
}

// MARK: - ABContentRule

/// WebKit Content Rule structure
public struct ABContentRule: Codable {
    public let trigger: ABTrigger
    public let action: ABAction

    public init(trigger: ABTrigger, action: ABAction) {
        self.trigger = trigger
        self.action = action
    }
}

// MARK: - ABTrigger

/// WebKit Content Rule Trigger
public struct ABTrigger: Codable {
    public let urlFilter: String?
    public let resourceType: [String]?
    public let ifDomain: [String]?
    public let unlessDomain: [String]?

    public init(
        urlFilter: String? = nil,
        resourceType: [String]? = nil,
        ifDomain: [String]? = nil,
        unlessDomain: [String]? = nil
    ) {
        self.urlFilter = urlFilter
        self.resourceType = resourceType
        self.ifDomain = ifDomain
        self.unlessDomain = unlessDomain
    }

    enum CodingKeys: String, CodingKey {
        case urlFilter = "url-filter"
        case resourceType = "resource-type"
        case ifDomain = "if-domain"
        case unlessDomain = "unless-domain"
    }
}

// MARK: - ABAction

/// WebKit Content Rule Action
public struct ABAction: Codable {
    public let type: String
    public let selector: String?

    public init(type: String, selector: String? = nil) {
        self.type = type
        self.selector = selector
    }
}

// MARK: - ABPageStats

/// Statistics for a specific page
public struct ABPageStats {
    public let url: URL
    public let blockedRequests: Int
    public let totalRequests: Int
    public let blockedDomains: Set<String>
    public let loadTime: Date

    public var blockingPercentage: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(blockedRequests) / Double(totalRequests) * 100
    }

    public init(
        url: URL,
        blockedRequests: Int = 0,
        totalRequests: Int = 0,
        blockedDomains: Set<String> = [],
        loadTime: Date = Date()
    ) {
        self.url = url
        self.blockedRequests = blockedRequests
        self.totalRequests = totalRequests
        self.blockedDomains = blockedDomains
        self.loadTime = loadTime
    }
}

// MARK: - ABGlobalStats

/// Global blocking statistics
public struct ABGlobalStats {
    public let totalBlockedRequests: Int
    public let totalRequests: Int
    public let blockedDomainsCount: Int
    public let sessionStartTime: Date
    public let bandwidthSaved: Int // in bytes

    public var blockingPercentage: Double {
        guard totalRequests > 0 else { return 0 }
        return Double(totalBlockedRequests) / Double(totalRequests) * 100
    }

    public var formattedBandwidthSaved: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bandwidthSaved))
    }

    public init(
        totalBlockedRequests: Int = 0,
        totalRequests: Int = 0,
        blockedDomainsCount: Int = 0,
        sessionStartTime: Date = Date(),
        bandwidthSaved: Int = 0
    ) {
        self.totalBlockedRequests = totalBlockedRequests
        self.totalRequests = totalRequests
        self.blockedDomainsCount = blockedDomainsCount
        self.sessionStartTime = sessionStartTime
        self.bandwidthSaved = bandwidthSaved
    }
}

// MARK: - ABResourceType

/// WebKit resource types for content blocking
public enum ABResourceType: String, CaseIterable {
    case document
    case image
    case styleSheet = "style-sheet"
    case script
    case font
    case media
    case fetch
    case websocket
    case other

    public static var allWebKitTypes: [String] {
        ABResourceType.allCases.map(\.rawValue)
    }
}

// MARK: - ABActionType

/// Content blocking action types
public enum ABActionType: String, CaseIterable {
    case block
    case cssDisplayNone = "css-display-none"
    case ignorePreviousRules = "ignore-previous-rules"
    case makeHTTPS = "make-https"
}

// MARK: - ABFilterCategory

/// Categories of filter lists for organization
public enum ABFilterCategory: String, CaseIterable {
    case ads = "Ads"
    case privacy = "Privacy"
    case social = "Social"
    case annoyances = "Annoyances"
    case regional = "Regional"
    case custom = "Custom"

    public var description: String {
        switch self {
        case .ads:
            "Block advertisements and promotional content"
        case .privacy:
            "Block tracking scripts and analytics"
        case .social:
            "Block social media widgets and buttons"
        case .annoyances:
            "Block cookie notices, popups, and other annoyances"
        case .regional:
            "Region-specific blocking lists"
        case .custom:
            "User-added custom filter lists"
        }
    }

    public var iconName: String {
        switch self {
        case .ads:
            "rectangle.slash"
        case .privacy:
            "eye.slash"
        case .social:
            "person.2.slash"
        case .annoyances:
            "exclamationmark.octagon"
        case .regional:
            "globe"
        case .custom:
            "gear"
        }
    }
}

// MARK: - ABUpdateStatus

/// Status of filter list updates
public enum ABUpdateStatus {
    case idle
    case updating
    case success(Date)
    case failed(Error)

    public var isUpdating: Bool {
        if case .updating = self {
            return true
        }
        return false
    }

    public var lastSuccessDate: Date? {
        if case let .success(date) = self {
            return date
        }
        return nil
    }

    public var error: Error? {
        if case let .failed(error) = self {
            return error
        }
        return nil
    }
}

// MARK: - Helper Extensions

public extension ABFilterList {
    /// Get the category this filter list belongs to
    var category: ABFilterCategory {
        let lowercaseName = name.lowercased()

        if lowercaseName.contains("privacy") {
            return .privacy
        } else if lowercaseName.contains("social") || lowercaseName.contains("fanboy") {
            return .social
        } else if lowercaseName.contains("annoyance") || lowercaseName.contains("cookie") {
            return .annoyances
        } else if isBuiltIn {
            return .ads
        } else {
            return .custom
        }
    }

    /// Get formatted last update time
    var formattedLastUpdate: String {
        guard let lastUpdated else {
            return "Never updated"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}

public extension ABPageStats {
    /// Get formatted blocking percentage
    var formattedBlockingPercentage: String {
        String(format: "%.1f%%", blockingPercentage)
    }

    /// Get summary description
    var summary: String {
        "\(blockedRequests)/\(totalRequests) blocked (\(formattedBlockingPercentage))"
    }
}

public extension ABGlobalStats {
    /// Get formatted blocking percentage
    var formattedBlockingPercentage: String {
        String(format: "%.1f%%", blockingPercentage)
    }

    /// Get session duration
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }

    /// Get formatted session duration
    var formattedSessionDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: sessionDuration) ?? "0m"
    }
}
