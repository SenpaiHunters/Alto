//
//  WebExtensionManager.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Foundation
import Observation
import os.log
import WebKit

// MARK: - ExtensionManager

@Observable
@MainActor
final class ExtensionManager {
    static let shared = ExtensionManager()

    var loadedExtensions: [String: WebExtension] = [:]
    private var extensionScripts: [String: String] = [:]
    private let permissionManager = ExtensionPermissionManager()
    private let logger = Logger(subsystem: "Alto.ExtensionManager", category: "ExtensionManager")

    private init() {
        logger.info("ExtensionManager initialized")
    }

    // MARK: - Extension Loading

    func loadExtension(from url: URL) async throws {
        logger.info("Loading extension from: \(url.path)")

        let manifest = try await loadManifest(from: url)
        let webExtension = createWebExtension(from: manifest, bundleURL: url)

        try await validateExtension(webExtension)

        loadedExtensions[webExtension.id] = webExtension
        await injectExtensionScripts(webExtension)

        logger.info("Extension loaded successfully: \(manifest.name) (\(webExtension.id))")
    }

    func unloadExtension(id: String) {
        defer {
            loadedExtensions.removeValue(forKey: id)
            extensionScripts.removeValue(forKey: id)
        }

        if let webExtension = loadedExtensions[id] {
            logger.info("Unloading extension: \(webExtension.manifest.name) (\(id))")
        } else {
            logger.warning("Attempted to unload unknown extension: \(id)")
        }
    }

    func getExtensionScripts(for url: URL) -> [String] {
        loadedExtensions.values.compactMap { webExtension in
            webExtension.matchesURL(url) ? extensionScripts.values.joined(separator: "\n") : nil
        }
    }

    // MARK: - Private Methods

    private func loadManifest(from url: URL) async throws -> ExtensionManifest {
        let manifestPath = url.appendingPathComponent("manifest.json")
        logger.info("Reading manifest from: \(manifestPath.path)")

        let manifestData = try Data(contentsOf: manifestPath)
        let manifest = try JSONDecoder().decode(ExtensionManifest.self, from: manifestData)

        logger.info("Parsed manifest for extension: \(manifest.name) v\(manifest.version)")
        return manifest
    }

    private func createWebExtension(from manifest: ExtensionManifest, bundleURL: URL) -> WebExtension {
        let webExtension = WebExtension(
            id: manifest.extensionId ?? UUID().uuidString,
            manifest: manifest,
            bundleURL: bundleURL
        )

        logger.info("Created WebExtension with ID: \(webExtension.id)")
        return webExtension
    }

    private func validateExtension(_ webExtension: WebExtension) async throws {
        try await permissionManager.validatePermissions(webExtension.manifest.permissions ?? [])
        logger.info("Extension validation passed for: \(webExtension.manifest.name)")
    }

    private func injectExtensionScripts(_ webExtension: WebExtension) async {
        guard let contentScripts = webExtension.manifest.contentScripts else { return }

        await withTaskGroup(of: Void.self) { group in
            for script in contentScripts {
                group.addTask { [weak self] in
                    await self?.processContentScript(script, for: webExtension)
                }
            }
        }
    }

    private func processContentScript(_ script: ContentScript, for webExtension: WebExtension) async {
        do {
            let scriptContent = try await loadScriptContent(from: script.js, in: webExtension.bundleURL)
            let scriptKey = "\(webExtension.id)_\(script.js.first ?? "")"
            extensionScripts[scriptKey] = scriptContent
        } catch {
            logger.error("Failed to load script content: \(error.localizedDescription)")
        }
    }

    private func loadScriptContent(from paths: [String], in bundleURL: URL) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            for path in paths {
                group.addTask {
                    let scriptURL = bundleURL.appendingPathComponent(path)
                    return try String(contentsOf: scriptURL)
                }
            }

            var combinedScript = ""
            for try await content in group {
                combinedScript += content + "\n"
            }
            return combinedScript
        }
    }
}

// MARK: - WebExtension

struct WebExtension: Identifiable, Hashable {
    let id: String
    let manifest: ExtensionManifest
    let bundleURL: URL

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WebExtension, rhs: WebExtension) -> Bool {
        lhs.id == rhs.id
    }

    func matchesURL(_ url: URL) -> Bool {
        guard let contentScripts = manifest.contentScripts else { return false }

        return contentScripts.contains { script in
            script.matches.contains { pattern in
                matchesPattern(pattern, url: url)
            }
        }
    }

    private func matchesPattern(_ pattern: String, url: URL) -> Bool {
        let regexPattern = pattern
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "://", with: "://")

        do {
            let regex = try NSRegularExpression(pattern: regexPattern)
            let range = NSRange(location: 0, length: url.absoluteString.count)
            return regex.firstMatch(in: url.absoluteString, options: [], range: range) != nil
        } catch {
            return false
        }
    }
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
    let icons: [String: String]?

    enum CodingKeys: String, CodingKey {
        case manifestVersion = "manifest_version"
        case name, version, description
        case extensionId = "extension_id"
        case contentScripts = "content_scripts"
        case background, permissions
        case hostPermissions = "host_permissions"
        case action
        case browserAction = "browser_action"
        case icons
    }
}

// MARK: - ContentScript

struct ContentScript: Codable, Hashable {
    let matches: [String]
    let js: [String]
    let css: [String]?
    let runAt: String?

    enum CodingKeys: String, CodingKey {
        case matches
        case js
        case css
        case runAt = "run_at"
    }
}

// MARK: - BackgroundScript

struct BackgroundScript: Codable, Hashable {
    let serviceWorker: String?
    let scripts: [String]?
    let persistent: Bool?

    enum CodingKeys: String, CodingKey {
        case serviceWorker = "service_worker"
        case scripts, persistent
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
