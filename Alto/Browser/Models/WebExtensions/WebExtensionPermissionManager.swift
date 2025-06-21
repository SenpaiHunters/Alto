//
//  WebExtensionPermissionManager.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Foundation

// MARK: - ExtensionPermissionManager

@MainActor
final class ExtensionPermissionManager {
    private let standardPermissions: Set<String> = [
        // Chrome Extension Permissions (from https://developer.chrome.com/docs/extensions/reference/permissions-list)
        "accessibilityFeatures.modify", "accessibilityFeatures.read", "activeTab", "alarms", "audio",
        "background", "bookmarks", "browsingData", "certificateProvider", "clipboardRead", "clipboardWrite",
        "contentSettings", "contextMenus", "cookies", "debugger", "declarativeContent", "declarativeNetRequest",
        "declarativeNetRequestWithHostAccess", "declarativeNetRequestFeedback", "dns", "desktopCapture",
        "documentScan", "downloads", "downloads.open", "downloads.ui", "enterprise.deviceAttributes",
        "enterprise.hardwarePlatform", "enterprise.networkingAttributes", "enterprise.platformKeys",
        "favicon", "fileBrowserHandler", "fileSystemProvider", "fontSettings", "gcm", "geolocation",
        "history", "identity", "identity.email", "idle", "loginState", "management", "nativeMessaging",
        "notifications", "offscreen", "pageCapture", "platformKeys", "power", "printerProvider",
        "printing", "printingMetrics", "privacy", "processes", "proxy", "readingList", "runtime",
        "scripting", "search", "sessions", "sidePanel", "storage", "system.cpu", "system.display",
        "system.memory", "system.storage", "tabCapture", "tabGroups", "tabs", "topSites", "tts",
        "ttsEngine", "unlimitedStorage", "userScripts", "vpnProvider", "wallpaper", "webAuthenticationProxy",
        "webNavigation", "webRequest", "webRequestBlocking", "commands", "menus", "theme", "find",
        "pkcs11", "browserSettings", "captivePortal", "devtools", "experiments", "mozillaAddons",
        "nativeMessagingFromContent", "telemetry", "urlbar", "declarativeWebRequest", "experimental",
        "cross-origin-isolated"
    ]

    private var grantedPermissions: [String: Set<String>] = [:]

    func validatePermissions(_ permissions: [String]) async throws {
        let invalidPermissions = permissions.filter { !isValidPermission($0) }
        guard invalidPermissions.isEmpty else {
            throw ExtensionError.invalidPermission(invalidPermissions.first!)
        }
    }

    func requestPermission(_ permission: String, for extensionId: String) async -> Bool {
        guard isValidPermission(permission) else { return false }

        if standardPermissions.contains(permission) || isHostPermission(permission) {
            grantPermissions([permission], for: extensionId)
            return true
        }

        return false
    }

    func grantPermissions(_ permissions: [String], for extensionId: String) {
        if grantedPermissions[extensionId] == nil {
            grantedPermissions[extensionId] = []
        }
        grantedPermissions[extensionId]?.formUnion(permissions)
    }

    func hasPermission(_ permission: String, for extensionId: String) -> Bool {
        grantedPermissions[extensionId]?.contains(permission) ?? false
    }

    func revokePermission(_ permission: String, for extensionId: String) {
        grantedPermissions[extensionId]?.remove(permission)
    }

    func revokeAllPermissions(for extensionId: String) {
        grantedPermissions.removeValue(forKey: extensionId)
    }

    func getGrantedPermissions(for extensionId: String) -> Set<String> {
        grantedPermissions[extensionId] ?? []
    }

    private func isValidPermission(_ permission: String) -> Bool {
        standardPermissions.contains(permission) ||
            isSpecialPermission(permission) ||
            isHostPermission(permission) ||
            isWildcardPattern(permission) ||
            isMatchPattern(permission)
    }

    private func isSpecialPermission(_ permission: String) -> Bool {
        permission == "<all_urls>"
    }

    private func isHostPermission(_ permission: String) -> Bool {
        permission.contains("://") ||
            permission.hasPrefix("http") ||
            permission.hasPrefix("https") ||
            permission.hasPrefix("file") ||
            permission.hasPrefix("ftp")
    }

    private func isWildcardPattern(_ permission: String) -> Bool {
        permission.contains("*") && (permission.contains(".") || permission.contains("/"))
    }

    private func isMatchPattern(_ permission: String) -> Bool {
        permission.range(of: #"\*://.*"#, options: .regularExpression) != nil
    }
}

// MARK: - ExtensionError

enum ExtensionError: Error, LocalizedError {
    case invalidPermission(String)
    case permissionDenied(String)
    case manifestParsingError(String)
    case extensionLoadError(String)

    var errorDescription: String? {
        switch self {
        case let .invalidPermission(permission):
            "Invalid permission: \(permission)"
        case let .permissionDenied(permission):
            "Permission denied: \(permission)"
        case let .manifestParsingError(error):
            "Manifest parsing error: \(error)"
        case let .extensionLoadError(error):
            "Extension load error: \(error)"
        }
    }
}
