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

    // MARK: - Properties

    var loadedExtensions: [String: WebExtension] = [:]
    var enabledExtensions: Set<String> = []
    private var extensionScripts: [String: [String]] = [:]
    private var extensionStyles: [String: [String]] = [:]
    private let permissionManager = ExtensionPermissionManager()
    private let storageManager = ExtensionStorageManager()
    private let logger = Logger(subsystem: "Alto.ExtensionManager", category: "ExtensionManager")

    // Extension state persistence
    private let extensionsDirectory: URL
    private let stateFileURL: URL

    // MARK: - Initialization

    private init() {
        // Set up directories
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let altoDir = appSupport.appendingPathComponent("Alto")
        extensionsDirectory = altoDir.appendingPathComponent("Extensions")
        stateFileURL = altoDir.appendingPathComponent("ExtensionState.json")

        createDirectoriesIfNeeded()
        logger.info("ExtensionManager initialized")
        loadPersistedExtensions()
    }

    // MARK: - Extension Management

    func loadExtension(from url: URL) async throws {
        logger.info("Loading extension from: \(url.path)")

        let manifest = try await loadManifest(from: url)
        let webExtension = createWebExtension(from: manifest, bundleURL: url)

        try await validateExtension(webExtension)

        // Install extension to managed directory
        let installedURL = try await installExtension(webExtension, from: url)
        let installedExtension = WebExtension(
            id: webExtension.id,
            manifest: webExtension.manifest,
            bundleURL: installedURL,
            isEnabled: true
        )

        loadedExtensions[installedExtension.id] = installedExtension
        enabledExtensions.insert(installedExtension.id)

        await processExtensionResources(installedExtension)
        persistExtensionState()

        logger.info("Extension loaded successfully: \(manifest.name) (\(installedExtension.id))")
    }

    func unloadExtension(id: String) {
        guard let webExtension = loadedExtensions[id] else {
            logger.warning("Attempted to unload unknown extension: \(id)")
            return
        }

        logger.info("Unloading extension: \(webExtension.manifest.name) (\(id))")

        // Clean up resources
        extensionScripts.removeValue(forKey: id)
        extensionStyles.removeValue(forKey: id)
        loadedExtensions.removeValue(forKey: id)
        enabledExtensions.remove(id)

        // Clean up storage
        storageManager.clearExtensionData(id)

        // Remove from disk
        removeExtensionFromDisk(id)

        persistExtensionState()
    }

    func toggleExtension(id: String) {
        guard loadedExtensions[id] != nil else { return }

        if enabledExtensions.contains(id) {
            enabledExtensions.remove(id)
            logger.info("Disabled extension: \(id)")
        } else {
            enabledExtensions.insert(id)
            logger.info("Enabled extension: \(id)")
        }

        persistExtensionState()
    }

    func reloadExtension(id: String) async throws {
        guard let webExtension = loadedExtensions[id] else {
            throw ExtensionError.extensionLoadError("Extension not found: \(id)")
        }

        logger.info("Reloading extension: \(webExtension.manifest.name)")

        // Clear existing resources
        extensionScripts.removeValue(forKey: id)
        extensionStyles.removeValue(forKey: id)

        // Reload resources
        await processExtensionResources(webExtension)

        logger.info("Extension reloaded: \(webExtension.manifest.name)")
    }

    // MARK: - Content Script Injection

    func getContentScripts(for url: URL) -> (scripts: [String], styles: [String]) {
        var matchingScripts: [String] = []
        var matchingStyles: [String] = []

        for (extensionId, webExtension) in loadedExtensions {
            guard enabledExtensions.contains(extensionId),
                  webExtension.matchesURL(url) else { continue }

            if let scripts = extensionScripts[extensionId] {
                matchingScripts.append(contentsOf: scripts)
            }

            if let styles = extensionStyles[extensionId] {
                matchingStyles.append(contentsOf: styles)
            }
        }

        return (scripts: matchingScripts, styles: matchingStyles)
    }

    func injectContentScripts(into webView: WKWebView, for url: URL) {
        let (scripts, styles) = getContentScripts(for: url)

        // Inject styles
        for style in styles {
            let styleScript = """
                (function() {
                    const style = document.createElement('style');
                    style.textContent = `\(style.replacingOccurrences(of: "`", with: "\\`"))`;
                    document.head.appendChild(style);
                })();
            """

            let userScript = WKUserScript(
                source: styleScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            webView.configuration.userContentController.addUserScript(userScript)
        }

        // Inject scripts
        for script in scripts {
            let userScript = WKUserScript(
                source: script,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            )
            webView.configuration.userContentController.addUserScript(userScript)
        }

        if !scripts.isEmpty || !styles.isEmpty {
            logger.info("Injected \(scripts.count) scripts and \(styles.count) styles for URL: \(url)")
        }
    }

    // MARK: - Extension Information

    func getExtensionInfo(id: String) -> WebExtension? {
        loadedExtensions[id]
    }

    func getAllExtensions() -> [WebExtension] {
        Array(loadedExtensions.values)
    }

    func getEnabledExtensions() -> [WebExtension] {
        loadedExtensions.values.filter { enabledExtensions.contains($0.id) }
    }

    // MARK: - Private Methods

    private func createDirectoriesIfNeeded() {
        do {
            try FileManager.default.createDirectory(
                at: extensionsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("Failed to create extensions directory: \(error.localizedDescription)")
        }
    }

    private func loadManifest(from url: URL) async throws -> ExtensionManifest {
        let manifestPath = url.appendingPathComponent("manifest.json")
        logger.info("Reading manifest from: \(manifestPath.path)")

        guard FileManager.default.fileExists(atPath: manifestPath.path) else {
            throw ExtensionError.manifestNotFound
        }

        let manifestData = try Data(contentsOf: manifestPath)

        do {
            let manifest = try JSONDecoder().decode(ExtensionManifest.self, from: manifestData)
            logger.info("Parsed manifest for extension: \(manifest.name) v\(manifest.version)")
            return manifest
        } catch {
            throw ExtensionError.invalidManifest(error.localizedDescription)
        }
    }

    private func createWebExtension(from manifest: ExtensionManifest, bundleURL: URL) -> WebExtension {
        let extensionId = manifest.extensionId ?? generateExtensionId(from: manifest)

        return WebExtension(
            id: extensionId,
            manifest: manifest,
            bundleURL: bundleURL,
            isEnabled: true
        )
    }

    private func generateExtensionId(from manifest: ExtensionManifest) -> String {
        let identifier = "\(manifest.name)-\(manifest.version)".lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
        return identifier
    }

    private func validateExtension(_ webExtension: WebExtension) async throws {
        // Validate manifest version
        guard [2, 3].contains(webExtension.manifest.manifestVersion) else {
            throw ExtensionError.unsupportedManifestVersion(webExtension.manifest.manifestVersion)
        }

        // Validate required fields
        guard !webExtension.manifest.name.isEmpty else {
            throw ExtensionError.invalidManifest("Extension name is required")
        }

        guard !webExtension.manifest.version.isEmpty else {
            throw ExtensionError.invalidManifest("Extension version is required")
        }

        // Validate permissions
        if let permissions = webExtension.manifest.permissions {
            try await permissionManager.validatePermissions(permissions)
        }

        // Validate content scripts
        if let contentScripts = webExtension.manifest.contentScripts {
            try validateContentScripts(contentScripts, bundleURL: webExtension.bundleURL)
        }

        // Validate popup files
        if let popupPath = webExtension.manifest.action?.defaultPopup ??
            webExtension.manifest.browserAction?.defaultPopup {
            let popupURL = webExtension.bundleURL.appendingPathComponent(popupPath)
            guard FileManager.default.fileExists(atPath: popupURL.path) else {
                throw ExtensionError.missingContentScript(popupPath)
            }
        }

        logger.info("Extension validation passed for: \(webExtension.manifest.name)")
    }

    private func validateContentScripts(_ contentScripts: [ContentScript], bundleURL: URL) throws {
        for script in contentScripts {
            // Validate JavaScript files exist
            for jsFile in script.js {
                let scriptPath = bundleURL.appendingPathComponent(jsFile)
                guard FileManager.default.fileExists(atPath: scriptPath.path) else {
                    throw ExtensionError.missingContentScript(jsFile)
                }
            }

            // Validate CSS files exist
            if let cssFiles = script.css {
                for cssFile in cssFiles {
                    let stylePath = bundleURL.appendingPathComponent(cssFile)
                    guard FileManager.default.fileExists(atPath: stylePath.path) else {
                        throw ExtensionError.missingContentScript(cssFile)
                    }
                }
            }

            // Validate match patterns
            for pattern in script.matches {
                guard isValidMatchPattern(pattern) else {
                    throw ExtensionError.invalidManifest("Invalid match pattern: \(pattern)")
                }
            }
        }
    }

    private func isValidMatchPattern(_ pattern: String) -> Bool {
        // Basic validation for match patterns
        if pattern == "<all_urls>" { return true }

        let validSchemes = ["http", "https", "file", "ftp", "*"]
        let components = pattern.components(separatedBy: "://")

        guard components.count == 2 else { return false }

        let scheme = components[0]
        return validSchemes.contains(scheme)
    }

    private func installExtension(_ webExtension: WebExtension, from sourceURL: URL) async throws -> URL {
        let destinationURL = extensionsDirectory.appendingPathComponent(webExtension.id)

        // Remove existing installation
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        // Copy extension files
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

        logger.info("Extension installed to: \(destinationURL.path)")
        return destinationURL
    }

    private func removeExtensionFromDisk(_ extensionId: String) {
        let extensionURL = extensionsDirectory.appendingPathComponent(extensionId)

        do {
            if FileManager.default.fileExists(atPath: extensionURL.path) {
                try FileManager.default.removeItem(at: extensionURL)
                logger.info("Removed extension from disk: \(extensionId)")
            }
        } catch {
            logger.error("Failed to remove extension from disk: \(error.localizedDescription)")
        }
    }

    private func processExtensionResources(_ webExtension: WebExtension) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { [weak self] in
                await self?.loadContentScripts(webExtension)
            }

            group.addTask { [weak self] in
                await self?.loadContentStyles(webExtension)
            }
        }
    }

    private func loadContentScripts(_ webExtension: WebExtension) async {
        guard let contentScripts = webExtension.manifest.contentScripts else { return }

        var scripts: [String] = []

        for contentScript in contentScripts {
            for jsFile in contentScript.js {
                do {
                    let scriptURL = webExtension.bundleURL.appendingPathComponent(jsFile)
                    let scriptContent = try String(contentsOf: scriptURL)

                    // Wrap script with extension context
                    let wrappedScript = wrapContentScript(scriptContent, extensionId: webExtension.id)
                    scripts.append(wrappedScript)
                } catch {
                    logger.error("Failed to load script \(jsFile): \(error.localizedDescription)")
                }
            }
        }

        if !scripts.isEmpty {
            extensionScripts[webExtension.id] = scripts
            logger.info("Loaded \(scripts.count) content scripts for extension: \(webExtension.manifest.name)")
        }
    }

    private func loadContentStyles(_ webExtension: WebExtension) async {
        guard let contentScripts = webExtension.manifest.contentScripts else { return }

        var styles: [String] = []

        for contentScript in contentScripts {
            if let cssFiles = contentScript.css {
                for cssFile in cssFiles {
                    do {
                        let styleURL = webExtension.bundleURL.appendingPathComponent(cssFile)
                        let styleContent = try String(contentsOf: styleURL)
                        styles.append(styleContent)
                    } catch {
                        logger.error("Failed to load style \(cssFile): \(error.localizedDescription)")
                    }
                }
            }
        }

        if !styles.isEmpty {
            extensionStyles[webExtension.id] = styles
            logger.info("Loaded \(styles.count) content styles for extension: \(webExtension.manifest.name)")
        }
    }

    private func wrapContentScript(_ script: String, extensionId: String) -> String {
        """
        (function() {
            // Extension context for \(extensionId)
            const extensionId = '\(extensionId)';

            // Inject extension APIs if not already available
            if (typeof chrome === 'undefined' || typeof chrome.runtime === 'undefined') {
                console.warn('Extension APIs not available for content script');
            }

            // Original script content
            \(script)
        })();
        """
    }

    private func loadPersistedExtensions() {
        guard FileManager.default.fileExists(atPath: stateFileURL.path) else {
            logger.info("No persisted extension state found")
            return
        }

        do {
            let data = try Data(contentsOf: stateFileURL)
            let state = try JSONDecoder().decode(ExtensionState.self, from: data)

            enabledExtensions = Set(state.enabledExtensions)

            // Load extensions from disk
            for extensionId in state.installedExtensions {
                Task {
                    await loadPersistedExtension(id: extensionId)
                }
            }

            logger.info("Loaded persisted extension state: \(state.installedExtensions.count) extensions")
        } catch {
            logger.error("Failed to load persisted extensions: \(error.localizedDescription)")
        }
    }

    private func loadPersistedExtension(id: String) async {
        let extensionURL = extensionsDirectory.appendingPathComponent(id)

        guard FileManager.default.fileExists(atPath: extensionURL.path) else {
            logger.warning("Persisted extension not found on disk: \(id)")
            return
        }

        do {
            let manifest = try await loadManifest(from: extensionURL)
            let webExtension = WebExtension(
                id: id,
                manifest: manifest,
                bundleURL: extensionURL,
                isEnabled: enabledExtensions.contains(id)
            )

            loadedExtensions[id] = webExtension
            await processExtensionResources(webExtension)

            logger.info("Loaded persisted extension: \(manifest.name)")
        } catch {
            logger.error("Failed to load persisted extension \(id): \(error.localizedDescription)")
        }
    }

    private func persistExtensionState() {
        let state = ExtensionState(
            installedExtensions: Array(loadedExtensions.keys),
            enabledExtensions: Array(enabledExtensions)
        )

        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: stateFileURL)
            logger.info("Persisted extension state")
        } catch {
            logger.error("Failed to persist extension state: \(error.localizedDescription)")
        }
    }
}

// MARK: - ExtensionState

private struct ExtensionState: Codable {
    let installedExtensions: [String]
    let enabledExtensions: [String]
}
