//
//  WebExtension.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Foundation

// MARK: - WebExtension

struct WebExtension: Identifiable, Hashable, Codable {
    let id: String
    let manifest: ExtensionManifest
    let bundleURL: URL
    var isEnabled: Bool

    // Computed properties
    var displayName: String {
        manifest.name
    }

    var version: String {
        manifest.version
    }

    var description: String {
        manifest.description ?? "No description available"
    }

    var iconURL: URL? {
        guard let icons = manifest.icons,
              let iconPath = icons["48"] ?? icons["32"] ?? icons["16"] ?? icons.values.first else {
            return nil
        }
        return bundleURL.appendingPathComponent(iconPath)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WebExtension, rhs: WebExtension) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - URL Matching

    func matchesURL(_ url: URL) -> Bool {
        guard let contentScripts = manifest.contentScripts else { return false }

        return contentScripts.contains { script in
            matchesContentScript(script, url: url)
        }
    }

    private func matchesContentScript(_ script: ContentScript, url: URL) -> Bool {
        // Check if URL matches any of the include patterns
        let matchesInclude = script.matches.contains { pattern in
            matchesPattern(pattern, url: url)
        }

        guard matchesInclude else { return false }

        // Check if URL is excluded
        if let excludeMatches = script.excludeMatches {
            let matchesExclude = excludeMatches.contains { pattern in
                matchesPattern(pattern, url: url)
            }
            if matchesExclude { return false }
        }

        return true
    }

    private func matchesPattern(_ pattern: String, url: URL) -> Bool {
        // Handle special patterns
        if pattern == "<all_urls>" {
            return true
        }

        // Parse the pattern
        guard let patternComponents = parseMatchPattern(pattern) else {
            return false
        }

        // Check scheme
        if patternComponents.scheme != "*", patternComponents.scheme != url.scheme {
            return false
        }

        // Check host
        if !matchesHost(patternComponents.host, url: url) {
            return false
        }

        // Check path
        if !matchesPath(patternComponents.path, url: url) {
            return false
        }

        return true
    }

    private func parseMatchPattern(_ pattern: String) -> MatchPatternComponents? {
        let components = pattern.components(separatedBy: "://")
        guard components.count == 2 else { return nil }

        let scheme = components[0]
        let rest = components[1]

        let pathIndex = rest.firstIndex(of: "/") ?? rest.endIndex
        let host = String(rest[..<pathIndex])
        let path = pathIndex < rest.endIndex ? String(rest[pathIndex...]) : "/*"

        return MatchPatternComponents(scheme: scheme, host: host, path: path)
    }

    private func matchesHost(_ patternHost: String, url: URL) -> Bool {
        guard let urlHost = url.host else { return false }

        if patternHost == "*" {
            return true
        }

        if patternHost.hasPrefix("*.") {
            let domain = String(patternHost.dropFirst(2))
            return urlHost == domain || urlHost.hasSuffix("." + domain)
        }

        return patternHost == urlHost
    }

    private func matchesPath(_ patternPath: String, url: URL) -> Bool {
        let urlPath = url.path.isEmpty ? "/" : url.path

        if patternPath == "/*" {
            return true
        }

        // Convert pattern to regex
        var regexPattern = patternPath
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: ".", with: "\\.")

        do {
            let regex = try NSRegularExpression(pattern: "^" + regexPattern + "$")
            let range = NSRange(location: 0, length: urlPath.count)
            return regex.firstMatch(in: urlPath, options: [], range: range) != nil
        } catch {
            return false
        }
    }

    // MARK: - Popup Support

    func hasPopup() -> Bool {
        getPopupPath() != nil
    }

    func getPopupPath() -> String? {
        manifest.action?.defaultPopup ??
            manifest.browserAction?.defaultPopup
    }

    func getPopupURL() -> URL? {
        guard let popupPath = getPopupPath() else { return nil }
        return bundleURL.appendingPathComponent(popupPath)
    }

    // MARK: - Permissions

    func hasPermission(_ permission: String) -> Bool {
        manifest.permissions?.contains(permission) == true ||
            manifest.hostPermissions?.contains(permission) == true
    }

    func getAllPermissions() -> [String] {
        var permissions: [String] = []

        if let manifestPermissions = manifest.permissions {
            permissions.append(contentsOf: manifestPermissions)
        }

        if let hostPermissions = manifest.hostPermissions {
            permissions.append(contentsOf: hostPermissions)
        }

        return permissions
    }

    // MARK: - Background Script

    func hasBackgroundScript() -> Bool {
        manifest.background != nil
    }

    func getBackgroundScriptPaths() -> [String] {
        guard let background = manifest.background else { return [] }

        if let serviceWorker = background.serviceWorker {
            return [serviceWorker]
        }

        if let page = background.page {
            return [page]
        }

        return background.scripts ?? []
    }

    // MARK: - Web Accessible Resources

    func isResourceWebAccessible(_ resourcePath: String, for url: URL) -> Bool {
        // Handle legacy format (array of strings)
        if let legacyResources = manifest.webAccessibleResourcesLegacy {
            return legacyResources.contains { pattern in
                matchesResourcePattern(pattern, resourcePath: resourcePath)
            }
        }

        // Handle new format (array of objects)
        guard let webAccessibleResources = manifest.webAccessibleResources else {
            return false
        }

        for resource in webAccessibleResources {
            // Check if resource matches
            let resourceMatches = resource.resources.contains { pattern in
                matchesResourcePattern(pattern, resourcePath: resourcePath)
            }

            guard resourceMatches else { continue }

            // Check if URL matches (if specified)
            if let matches = resource.matches {
                return matches.contains { pattern in
                    matchesPattern(pattern, url: url)
                }
            }

            return true
        }

        return false
    }

    private func matchesResourcePattern(_ pattern: String, resourcePath: String) -> Bool {
        if pattern == resourcePath {
            return true
        }

        // Convert pattern to regex
        var regexPattern = pattern
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: ".", with: "\\.")

        do {
            let regex = try NSRegularExpression(pattern: "^" + regexPattern + "$")
            let range = NSRange(location: 0, length: resourcePath.count)
            return regex.firstMatch(in: resourcePath, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

// MARK: - MatchPatternComponents

private struct MatchPatternComponents {
    let scheme: String
    let host: String
    let path: String
}

// MARK: - ExtensionManifest

struct ExtensionManifest: Codable, Hashable {
    let manifestVersion: Int
    let name: String
    let version: String
    let description: String?
    let extensionId: String?
    let contentScripts: [ContentScript]?
    let background: BackgroundScript?
    let permissions: [String]?
    let hostPermissions: [String]?
    let action: ActionDefinition?
    let browserAction: ActionDefinition?
    let pageAction: ActionDefinition?
    let icons: [String: String]?
    let webAccessibleResources: [WebAccessibleResource]?
    let webAccessibleResourcesLegacy: [String]? // For manifest v2 compatibility
    let contentSecurityPolicy: String?
    let options: OptionsDefinition?
    let optionsUI: OptionsUIDefinition?
    let commands: [String: CommandDefinition]?

    // Additional fields for compatibility
    let author: String?
    let shortName: String?
    let defaultLocale: String?
    let incognito: String?
    let minimumChromeVersion: String?
    let updateURL: String?
    let storage: StorageDefinition?

    enum CodingKeys: String, CodingKey {
        case manifestVersion = "manifest_version"
        case name, version, description
        case extensionId = "extension_id"
        case contentScripts = "content_scripts"
        case background, permissions
        case hostPermissions = "host_permissions"
        case action
        case browserAction = "browser_action"
        case pageAction = "page_action"
        case icons
        case webAccessibleResources = "web_accessible_resources"
        case contentSecurityPolicy = "content_security_policy"
        case options
        case optionsUI = "options_ui"
        case commands
        case author
        case shortName = "short_name"
        case defaultLocale = "default_locale"
        case incognito
        case minimumChromeVersion = "minimum_chrome_version"
        case updateURL = "update_url"
        case storage
    }

    // Custom decoder to handle both legacy and new web_accessible_resources formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        manifestVersion = try container.decode(Int.self, forKey: .manifestVersion)
        name = try container.decode(String.self, forKey: .name)
        version = try container.decode(String.self, forKey: .version)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        extensionId = try container.decodeIfPresent(String.self, forKey: .extensionId)
        contentScripts = try container.decodeIfPresent([ContentScript].self, forKey: .contentScripts)
        background = try container.decodeIfPresent(BackgroundScript.self, forKey: .background)
        permissions = try container.decodeIfPresent([String].self, forKey: .permissions)
        hostPermissions = try container.decodeIfPresent([String].self, forKey: .hostPermissions)
        action = try container.decodeIfPresent(ActionDefinition.self, forKey: .action)
        browserAction = try container.decodeIfPresent(ActionDefinition.self, forKey: .browserAction)
        pageAction = try container.decodeIfPresent(ActionDefinition.self, forKey: .pageAction)
        icons = try container.decodeIfPresent([String: String].self, forKey: .icons)
        contentSecurityPolicy = try container.decodeIfPresent(String.self, forKey: .contentSecurityPolicy)
        options = try container.decodeIfPresent(OptionsDefinition.self, forKey: .options)
        optionsUI = try container.decodeIfPresent(OptionsUIDefinition.self, forKey: .optionsUI)
        commands = try container.decodeIfPresent([String: CommandDefinition].self, forKey: .commands)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        shortName = try container.decodeIfPresent(String.self, forKey: .shortName)
        defaultLocale = try container.decodeIfPresent(String.self, forKey: .defaultLocale)
        incognito = try container.decodeIfPresent(String.self, forKey: .incognito)
        minimumChromeVersion = try container.decodeIfPresent(String.self, forKey: .minimumChromeVersion)
        updateURL = try container.decodeIfPresent(String.self, forKey: .updateURL)
        storage = try container.decodeIfPresent(StorageDefinition.self, forKey: .storage)

        // Handle web_accessible_resources - can be array of strings (v2) or array of objects (v3)
        if container.contains(.webAccessibleResources) {
            if let legacyResources = try? container.decode([String].self, forKey: .webAccessibleResources) {
                webAccessibleResourcesLegacy = legacyResources
                webAccessibleResources = nil
            } else if let newResources = try? container.decode(
                [WebAccessibleResource].self,
                forKey: .webAccessibleResources
            ) {
                webAccessibleResources = newResources
                webAccessibleResourcesLegacy = nil
            } else {
                webAccessibleResources = nil
                webAccessibleResourcesLegacy = nil
            }
        } else {
            webAccessibleResources = nil
            webAccessibleResourcesLegacy = nil
        }
    }
}

// MARK: - ContentScript

struct ContentScript: Codable, Hashable {
    let matches: [String]
    let js: [String]
    let css: [String]?
    let runAt: String?
    let allFrames: Bool?
    let excludeMatches: [String]?
    let includeGlobs: [String]?
    let excludeGlobs: [String]?
    let matchAboutBlank: Bool?

    enum CodingKeys: String, CodingKey {
        case matches
        case js
        case css
        case runAt = "run_at"
        case allFrames = "all_frames"
        case excludeMatches = "exclude_matches"
        case includeGlobs = "include_globs"
        case excludeGlobs = "exclude_globs"
        case matchAboutBlank = "match_about_blank"
    }

    var injectionTime: ContentScriptInjectionTime {
        switch runAt {
        case "document_start":
            .documentStart
        case "document_end":
            .documentEnd
        case "document_idle":
            .documentIdle
        default:
            .documentIdle
        }
    }
}

// MARK: - ContentScriptInjectionTime

enum ContentScriptInjectionTime {
    case documentStart
    case documentEnd
    case documentIdle
}

// MARK: - BackgroundScript

struct BackgroundScript: Codable, Hashable {
    let serviceWorker: String?
    let scripts: [String]?
    let page: String? // For manifest v2
    let persistent: Bool?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case serviceWorker = "service_worker"
        case scripts, page, persistent, type
    }
}

// MARK: - ActionDefinition

struct ActionDefinition: Codable, Hashable {
    let defaultTitle: String?
    let defaultIcon: [String: String]?
    let defaultPopup: String?

    enum CodingKeys: String, CodingKey {
        case defaultTitle = "default_title"
        case defaultIcon = "default_icon"
        case defaultPopup = "default_popup"
    }
}

// MARK: - WebAccessibleResource

struct WebAccessibleResource: Codable, Hashable {
    let resources: [String]
    let matches: [String]?
    let extensionIds: [String]?
    let usesDynamicUrl: Bool?

    enum CodingKeys: String, CodingKey {
        case resources
        case matches
        case extensionIds = "extension_ids"
        case usesDynamicUrl = "use_dynamic_url"
    }
}

// MARK: - OptionsDefinition

struct OptionsDefinition: Codable, Hashable {
    let page: String?
    let chromeStyle: Bool?
    let openInTab: Bool?

    enum CodingKeys: String, CodingKey {
        case page
        case chromeStyle = "chrome_style"
        case openInTab = "open_in_tab"
    }
}

// MARK: - OptionsUIDefinition

struct OptionsUIDefinition: Codable, Hashable {
    let page: String?
    let chromeStyle: Bool?
    let openInTab: Bool?

    enum CodingKeys: String, CodingKey {
        case page
        case chromeStyle = "chrome_style"
        case openInTab = "open_in_tab"
    }
}

// MARK: - CommandDefinition

struct CommandDefinition: Codable, Hashable {
    let suggestedKey: SuggestedKey?
    let description: String?
    let global: Bool?

    enum CodingKeys: String, CodingKey {
        case suggestedKey = "suggested_key"
        case description, global
    }
}

// MARK: - SuggestedKey

struct SuggestedKey: Codable, Hashable {
    let `default`: String?
    let mac: String?
    let linux: String?
    let windows: String?
    let chromeos: String?
}

// MARK: - StorageDefinition

struct StorageDefinition: Codable, Hashable {
    let managedSchema: String?

    enum CodingKeys: String, CodingKey {
        case managedSchema = "managed_schema"
    }
}
