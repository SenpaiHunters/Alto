//
//  WebExtensionWindowManager.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import os.log
import SwiftUI
import WebKit

// MARK: - ExtensionWindowManager

@MainActor
final class ExtensionWindowManager: ObservableObject {
    static let shared = ExtensionWindowManager()

    private let logger = Logger(subsystem: "Alto.ExtensionManager", category: "WindowManager")
    private var extensionWindows: [String: NSWindow] = [:]

    private init() {
        logger.info("ExtensionWindowManager initialized")
    }

    func openExtensionWindow(_ webExtension: WebExtension) {
        logger.info("Opening extension window for: \(webExtension.manifest.name)")
        openExtensionPopup(webExtension)
    }

    func openExtensionPopup(_ webExtension: WebExtension) {
        logger.info("Opening extension popup for: \(webExtension.manifest.name) (ID: \(webExtension.id))")

        closeExistingWindow(for: webExtension.id)

        let window = createWindow(for: webExtension)
        setupWindowDelegate(window, extensionId: webExtension.id, extensionName: webExtension.manifest.name)

        extensionWindows[webExtension.id] = window
        window.makeKeyAndOrderFront(nil)

        logger.info("Window displayed for extension: \(webExtension.manifest.name)")
    }

    private func closeExistingWindow(for extensionId: String) {
        guard let existingWindow = extensionWindows[extensionId] else { return }

        logger.info("Closing existing window for extension")
        existingWindow.close()
        extensionWindows.removeValue(forKey: extensionId)
    }

    private func createWindow(for webExtension: WebExtension) -> NSWindow {
        let contentView = ExtensionPopupView(webExtension: webExtension)
        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.contentView = hostingView
        window.title = webExtension.manifest.name
        window.center()

        return window
    }

    private func setupWindowDelegate(_ window: NSWindow, extensionId: String, extensionName: String) {
        window.delegate = ExtensionWindowDelegate { [weak self] in
            self?.logger.info("Window closed for extension: \(extensionName)")
            self?.extensionWindows.removeValue(forKey: extensionId)
        }
    }
}

// MARK: - ExtensionWindowDelegate

final class ExtensionWindowDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> ()

    init(onClose: @escaping () -> ()) {
        self.onClose = onClose
        super.init()
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}

// MARK: - ExtensionPopupView

struct ExtensionPopupView: View {
    let webExtension: WebExtension
    @State private var webView: WKWebView?
    @State private var navigationDelegate: NavigationDelegate?
    @State private var isLoading = true
    @State private var hasPopup = false
    @State private var loadingError: String?
    @State private var loadingProgress = "Initializing..."

    private let logger = Logger(subsystem: "Alto.ExtensionManager", category: "PopupView")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .onAppear {
            logger.info("ExtensionPopupView appeared for: \(webExtension.manifest.name)")
            loadExtensionPopup()
        }
    }

    private var headerView: some View {
        HStack {
            extensionIcon
            extensionInfo
            Spacer()
            closeButton
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }

    private var extensionIcon: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.gradient)
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "puzzlepiece.extension")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            )
    }

    private var extensionInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(webExtension.manifest.name)
                .font(.headline)
                .fontWeight(.semibold)

            Text("Version \(webExtension.manifest.version)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var closeButton: some View {
        Button("Close") {
            logger.info("Close button pressed for extension: \(webExtension.manifest.name)")
            NSApplication.shared.keyWindow?.performClose(nil)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }

    @ViewBuilder
    private var contentView: some View {
        if let error = loadingError {
            errorStateView(error: error)
        } else if hasPopup, let webView {
            WebViewRepresentable(webView: webView)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isLoading {
            loadingStateView
        } else {
            noPopupStateView
        }
    }

    private func errorStateView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Failed to Load Extension")
                .font(.title2)
                .fontWeight(.medium)

            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                logger.info("Retry button pressed for extension: \(webExtension.manifest.name)")
                resetLoadingState()
                loadExtensionPopup()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Loading Extension...")
                .font(.headline)

            Text(loadingProgress)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            debugInfoView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var debugInfoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Extension ID: \(webExtension.id)")
            Text("Bundle: \(webExtension.bundleURL.lastPathComponent)")

            if let popup = webExtension.manifest.action?.defaultPopup {
                Text("Popup: \(popup)")
            } else {
                Text("No popup defined")
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.top)
    }

    private var noPopupStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .opacity(0.6)

            Text("No Popup Interface")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("This extension doesn't have a popup interface defined")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let description = webExtension.manifest.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            extensionDetailsView
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var extensionDetailsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extension Details")
                .font(.headline)
                .padding(.bottom, 4)

            DetailRow(label: "ID", value: webExtension.id)
            DetailRow(label: "Version", value: webExtension.manifest.version)
            DetailRow(label: "Manifest", value: "v\(webExtension.manifest.manifestVersion)")

            if let permissions = webExtension.manifest.permissions, !permissions.isEmpty {
                DetailRow(label: "Permissions", value: permissions.joined(separator: ", "))
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }

    private func resetLoadingState() {
        loadingError = nil
        isLoading = true
        loadingProgress = "Initializing..."
    }

    private func loadExtensionPopup() {
        logger.info("Starting popup load for extension: \(webExtension.manifest.name)")
        loadingProgress = "Checking popup configuration..."

        logExtensionActions()

        guard let popupPath = getPopupPath() else {
            handleNoPopup()
            return
        }

        logger.info("Found popup path: \(popupPath) for extension: \(webExtension.manifest.name)")
        loadingProgress = "Creating WebView configuration..."

        let webView = createWebView()
        setupNavigationDelegate(for: webView)
        loadPopupContent(webView: webView, popupPath: popupPath)
    }

    private func logExtensionActions() {
        if let action = webExtension.manifest.action {
            logger.info("Extension action object found for \(webExtension.manifest.name)")
            logger.info("Action defaultTitle: \(action.defaultTitle ?? "none")")
            logger.info("Action defaultPopup: \(action.defaultPopup ?? "none")")
            logger.info("Action defaultIcon: \(action.defaultIcon?.keys.joined(separator: ", ") ?? "none")")
        } else {
            logger.info("No action object found for extension: \(webExtension.manifest.name)")
        }
    }

    private func getPopupPath() -> String? {
        if let actionPopup = webExtension.manifest.action?.defaultPopup {
            logger.info("Found popup in action.default_popup: \(actionPopup)")
            return actionPopup
        }

        if let browserAction = webExtension.manifest.browserAction {
            logger.info("Extension browser_action object found for \(webExtension.manifest.name)")
            logger.info("BrowserAction defaultTitle: \(browserAction.defaultTitle ?? "none")")
            logger.info("BrowserAction defaultPopup: \(browserAction.defaultPopup ?? "none")")
            logger
                .info("BrowserAction defaultIcon: \(browserAction.defaultIcon?.keys.joined(separator: ", ") ?? "none")")

            if let browserActionPopup = browserAction.defaultPopup {
                logger.info("Found popup in browser_action.default_popup: \(browserActionPopup)")
                return browserActionPopup
            }
        }

        return nil
    }

    private func handleNoPopup() {
        logger.info("No popup defined for extension: \(webExtension.manifest.name)")
        loadingProgress = "No popup interface defined"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            hasPopup = false
        }
    }

    private func createWebView() -> WKWebView {
        let config = WKWebViewConfiguration()

        #if DEBUG
            config.preferences.setValue(true, forKey: "developerExtrasEnabled")
        #endif

        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.preferences.setValue(true, forKey: "javaScriptCanAccessClipboard")

        if #available(macOS 10.15, *) {
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }

        setupWebExtensionsAPI(config: config)
        addUserScripts(config: config)

        return WKWebView(frame: .zero, configuration: config)
    }

    private func setupWebExtensionsAPI(config: WKWebViewConfiguration) {
        let bridge = WebExtensionsAPIBridge.shared
        let handlers = [
            "altoExtensions", "chrome.tabs", "chrome.runtime", "chrome.storage",
            "chrome.webRequest", "chrome.contextMenus", "chrome.notifications",
            "chrome.bookmarks", "chrome.history", "browser.tabs", "browser.runtime",
            "browser.storage", "browser.webRequest", "browser.contextMenus",
            "browser.notifications", "browser.bookmarks", "browser.history"
        ]

        for handler in handlers {
            config.userContentController.add(bridge, name: handler)
        }

        logger.info("Added WebExtensions API bridge message handlers")
    }

    private func addUserScripts(config: WKWebViewConfiguration) {
        let bridge = WebExtensionsAPIBridge.shared

        let apiScript = WKUserScript(
            source: bridge.generateWebExtensionsAPI(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(apiScript)

        // FONTAWESOME ICON FIX
        let fontAwesomeFixScript = WKUserScript(
            source: """
                (function() {
                    console.log('🎨 Setting up FontAwesome icon fix...');

                    window._altoModuleLoader = {
                        processedModules: new Set(),
                        moduleCache: new Map(),
                        loadedResources: new Set()
                    };

                    // 1. FontAwesome icon replacement map
                    const iconMap = {
                        'film': '🎬',
                        'oh-popups': '🚫',
                        'eyeph-slash': '👁️',
                        'headermode-text-size': '📝',
                        'code': '💻',
                        'list-alt': '📋',
                        'cogs': '⚙️',
                        'bolt': '⚡',
                        'eye-dropper': '🎨',
                        'commentlist-alt': '💬',
                        'power-off': '⏻',
                        'lock': '🔒',
                        'unlock': '🔓',
                        'refresh': '🔄',
                        'eraser': '🧹',
                        'dashboard': '📊',
                        'logger': '📝'
                    };

                    // 2. Enhanced createElement override
                    const originalCreateElement = document.createElement;
                    document.createElement = function(tagName) {
                        const element = originalCreateElement.call(this, tagName);

                        if (tagName.toLowerCase() === 'script') {
                            if (element.type === 'module') {
                                element.type = 'text/javascript';
                                console.log('🔄 Converted module script to regular script');
                            }
                        }

                        return element;
                    };

                    // 3. Fix fetch for local resources
                    const originalFetch = window.fetch;
                    window.fetch = function(url, options) {
                        console.log('🌐 Fetch request: ' + url);

                        if (typeof url === 'string' && (url.startsWith('./') || url.startsWith('../') || !url.includes('://'))) {
                            return new Promise((resolve, reject) => {
                                const xhr = new XMLHttpRequest();
                                xhr.open('GET', url, true);
                                xhr.onload = function() {
                                    if (xhr.status >= 200 && xhr.status < 300) {
                                        resolve(new Response(xhr.responseText, {
                                            status: xhr.status,
                                            statusText: xhr.statusText,
                                            headers: new Headers({
                                                'Content-Type': xhr.getResponseHeader('Content-Type') || 'text/plain'
                                            })
                                        }));
                                    } else {
                                        reject(new Error('Network response was not ok'));
                                    }
                                };
                                xhr.onerror = function() {
                                    reject(new Error('Network error'));
                                };
                                xhr.send();
                            });
                        }

                        return originalFetch.call(this, url, options);
                    };

                    // 4. DOM ready handler for icon fixing
                    function fixIconsWhenReady() {
                        if (document.readyState === 'loading') {
                            document.addEventListener('DOMContentLoaded', fixIconsWhenReady);
                            return;
                        }

                        setTimeout(() => {
                            console.log('🎯 Starting icon replacement...');

                            // Find all text nodes and replace icon names with emojis
                            function replaceIconsInTextNodes(node) {
                                if (node.nodeType === Node.TEXT_NODE) {
                                    let text = node.textContent;
                                    let hasReplacement = false;

                                    for (const [iconName, emoji] of Object.entries(iconMap)) {
                                        if (text.includes(iconName)) {
                                            text = text.replace(new RegExp(iconName, 'g'), emoji);
                                            hasReplacement = true;
                                        }
                                    }

                                    if (hasReplacement) {
                                        node.textContent = text;
                                        console.log('🎨 Replaced icons in text: ' + text);
                                    }
                                } else if (node.nodeType === Node.ELEMENT_NODE) {
                                    // Process child nodes
                                    for (let child of node.childNodes) {
                                        replaceIconsInTextNodes(child);
                                    }

                                    // Handle FontAwesome classes
                                    if (node.className && typeof node.className === 'string') {
                                        const classes = node.className.split(' ');
                                        for (const className of classes) {
                                            if (className.startsWith('fa-')) {
                                                const iconName = className.substring(3);
                                                if (iconMap[iconName]) {
                                                    node.textContent = iconMap[iconName];
                                                    node.style.fontFamily = 'system-ui, -apple-system, sans-serif';
                                                    node.style.fontSize = '16px';
                                                    console.log('🎨 Replaced FA icon: ' + iconName + ' with ' + iconMap[iconName]);
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            replaceIconsInTextNodes(document.body);

                            // Also check for elements with specific data attributes
                            const dataElements = document.querySelectorAll('[data-i18n]');
                            dataElements.forEach(element => {
                                const dataI18n = element.getAttribute('data-i18n');
                                if (iconMap[dataI18n]) {
                                    element.textContent = iconMap[dataI18n];
                                    console.log('🎨 Replaced data-i18n icon: ' + dataI18n);
                                }
                            });

                            console.log('✅ Icon replacement completed');
                        }, 100);
                    }

                    fixIconsWhenReady();

                    console.log('✅ FontAwesome icon fix initialized');
                })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(fontAwesomeFixScript)

        logger.info("Added WebExtensions API polyfill and FontAwesome icon fix")
    }

    private func setupNavigationDelegate(for webView: WKWebView) {
        let delegate = NavigationDelegate(
            logger: logger,
            extensionName: webExtension.manifest.name,
            onLoadStart: {
                DispatchQueue.main.async {
                    loadingProgress = "Loading extension content..."
                }
            },
            onLoadFinish: {
                DispatchQueue.main.async {
                    isLoading = false
                    loadingProgress = "Loaded successfully"
                }
            },
            onLoadFail: { error in
                DispatchQueue.main.async {
                    loadingError = "Failed to load: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        )

        navigationDelegate = delegate
        webView.navigationDelegate = delegate
        logger.info("Set navigation delegate for WebView")
    }

    private func loadPopupContent(webView: WKWebView, popupPath: String) {
        loadingProgress = "Loading popup HTML..."

        let extensionURL = webExtension.bundleURL.appendingPathComponent(popupPath)
        logger.info("Attempting to load popup from: \(extensionURL.path)")

        DispatchQueue.main.async {
            handlePopupLoading(webView: webView, extensionURL: extensionURL)
        }
    }

    private func handlePopupLoading(webView: WKWebView, extensionURL: URL) {
        guard FileManager.default.fileExists(atPath: extensionURL.path) else {
            handleMissingPopupFile(extensionURL: extensionURL)
            return
        }

        logger.info("Popup file exists, loading: \(extensionURL.path)")
        logLoadingDetails(extensionURL: extensionURL)

        webView.loadFileURL(extensionURL, allowingReadAccessTo: webExtension.bundleURL)

        self.webView = webView
        hasPopup = true

        setupLoadingTimeout()
    }

    private func logLoadingDetails(extensionURL: URL) {
        let name = webExtension.manifest.name
        logger.info("🚀 [\(name)] Loading popup directly with file URL access")
        logger.info("📁 [\(name)] Extension URL: \(extensionURL)")
        logger.info("📂 [\(name)] Bundle URL: \(webExtension.bundleURL)")

        let isReadable = FileManager.default.isReadableFile(atPath: extensionURL.path)
        logger.info("🔐 [\(name)] File permissions - Readable: \(isReadable)")

        do {
            let htmlContent = try String(contentsOf: extensionURL, encoding: .utf8)
            logger.info("[\(name)] HTML content (\(htmlContent.count) characters)")
        } catch {
            logger.error("[\(name)] Could not read HTML for logging: \(error.localizedDescription)")
        }
    }

    private func handleMissingPopupFile(extensionURL: URL) {
        logger.error("Popup file not found at: \(extensionURL.path)")

        let extensionDir = webExtension.bundleURL
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: extensionDir.path) {
            logger.info("Extension directory contents: \(contents.joined(separator: ", "))")
        } else {
            logger.error("Could not read extension directory: \(extensionDir.path)")
        }

        loadingError = "Popup file not found: \(extensionURL.lastPathComponent)"
        hasPopup = false
        isLoading = false
    }

    private func setupLoadingTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            if isLoading {
                logger.warning("Extension popup loading timed out for: \(webExtension.manifest.name)")
                loadingError = "Loading timed out after 30 seconds"
                isLoading = false
            }
        }
    }
}

// MARK: - DetailRow

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text(value)
                .foregroundColor(.secondary)
            Spacer()
        }
        .font(.caption)
    }
}

// MARK: - NavigationDelegate

private final class NavigationDelegate: NSObject, WKNavigationDelegate {
    private let logger: Logger
    private let extensionName: String
    private let onLoadStart: () -> ()
    private let onLoadFinish: () -> ()
    private let onLoadFail: (Error) -> ()

    init(
        logger: Logger,
        extensionName: String,
        onLoadStart: @escaping () -> (),
        onLoadFinish: @escaping () -> (),
        onLoadFail: @escaping (Error) -> ()
    ) {
        self.logger = logger
        self.extensionName = extensionName
        self.onLoadStart = onLoadStart
        self.onLoadFinish = onLoadFinish
        self.onLoadFail = onLoadFail
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        logger.info("🚀 [\(extensionName)] WebView STARTED provisional navigation")
        logger.info("🔗 [\(extensionName)] Loading URL: \(webView.url?.absoluteString ?? "nil")")
        onLoadStart()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        logger.info("📄 [\(extensionName)] WebView COMMITTED navigation")
        logger.info("🔗 [\(extensionName)] Committed URL: \(webView.url?.absoluteString ?? "nil")")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        logger.info("✅ [\(extensionName)] WebView FINISHED navigation")
        logger.info("🔗 [\(extensionName)] Final URL: \(webView.url?.absoluteString ?? "nil")")

        // CRITICAL FIX: Force module execution and visibility fix
        forceModuleExecution(webView: webView)

        onLoadFinish()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        logger.error("❌ [\(extensionName)] WebView FAILED navigation: \(error.localizedDescription)")
        onLoadFail(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        logger.error("❌ [\(extensionName)] WebView FAILED provisional navigation: \(error.localizedDescription)")
        onLoadFail(error)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> ()
    ) {
        let url = navigationAction.request.url?.absoluteString ?? "unknown"
        logger.info("🤔 [\(extensionName)] Navigation policy request: \(url)")

        guard let requestURL = navigationAction.request.url else {
            logger.warning("🚫 [\(extensionName)] BLOCKING navigation with nil URL")
            decisionHandler(.cancel)
            return
        }

        // Handle extension internal navigation
        if requestURL.scheme == "file" {
            let fileName = requestURL.lastPathComponent

            // Block navigation to extension pages that should open in new windows/tabs
            if fileName.contains("dashboard.html") ||
                fileName.contains("logger-ui.html") ||
                fileName.contains("options.html") ||
                fileName.contains("settings.html") {
                logger.info("🚫 [\(extensionName)] BLOCKING navigation to extension page: \(fileName)")

                // Instead of navigating, trigger the proper extension API call
                let extensionPageScript = """
                    (function() {
                        console.log('🔗 Intercepted navigation to: \(fileName)');

                        // Simulate opening in new tab/window via extension API
                        if (typeof chrome !== 'undefined' && chrome.tabs && chrome.tabs.create) {
                            chrome.tabs.create({
                                url: '\(url)',
                                active: true
                            });
                        } else {
                            console.log('📝 Would open extension page: \(fileName)');

                            // Show a notification or modal instead
                            const notification = document.createElement('div');
                            notification.style.cssText = `
                                position: fixed;
                                top: 10px;
                                right: 10px;
                                background: #333;
                                color: white;
                                padding: 10px;
                                border-radius: 5px;
                                z-index: 10000;
                                font-size: 12px;
                            `;
                            notification.textContent = 'Extension page: \(fileName)';
                            document.body.appendChild(notification);

                            setTimeout(() => {
                                if (notification.parentNode) {
                                    notification.parentNode.removeChild(notification);
                                }
                            }, 3000);
                        }

                        return false;
                    })();
                """

                webView.evaluateJavaScript(extensionPageScript) { _, error in
                    if let error {
                        self.logger
                            .error(
                                "❌ [\(self.extensionName)] Extension page script error: \(error.localizedDescription)"
                            )
                    }
                }

                decisionHandler(.cancel)
                return
            }

            // Allow navigation to the main popup file
            let mainPopupFile = requestURL.lastPathComponent
            if mainPopupFile == "popup.html" || mainPopupFile == "popup-fenix.html" {
                logger.info("✅ [\(extensionName)] ALLOWING navigation to main popup: \(mainPopupFile)")
                decisionHandler(.allow)
                return
            }

            logger.info("✅ [\(extensionName)] ALLOWING file navigation to: \(url)")
            decisionHandler(.allow)
        } else if requestURL.scheme == "about" {
            logger.info("✅ [\(extensionName)] ALLOWING about navigation to: \(url)")
            decisionHandler(.allow)
        } else {
            logger.warning("🚫 [\(extensionName)] BLOCKING external navigation to: \(url)")
            decisionHandler(.cancel)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> ()
    ) {
        let url = navigationResponse.response.url?.absoluteString ?? "unknown"
        let mimeType = navigationResponse.response.mimeType ?? "unknown"
        logger.info("📥 [\(extensionName)] Navigation response: \(url)")
        logger.info("📋 [\(extensionName)] MIME type: \(mimeType)")

        decisionHandler(.allow)
    }

    private func forceModuleExecution(webView: WKWebView) {
        // Wait a moment for DOM to be ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.executeModuleFix(webView: webView)
        }
    }

    private func executeModuleFix(webView: WKWebView) {
        let completeFixScript = """
            (function() {
                console.log('🔧 [\(extensionName)] Starting complete extension fix...');

                try {
                    // 1. Force body visibility
                    if (document.body) {
                        document.body.style.setProperty('opacity', '1', 'important');
                        document.body.style.setProperty('visibility', 'visible', 'important');
                        document.body.style.setProperty('display', 'block', 'important');
                    }

                    // 2. Icon replacement map (more comprehensive)
                    const iconMap = {
                        'film': '🎬',
                        'oh-popups': '🚫',
                        'eyeph-slash': '👁️‍🗨️',
                        'headermode-text-size': '📝',
                        'code': '💻',
                        'list-alt': '📋',
                        'cogs': '⚙️',
                        'bolt': '⚡',
                        'eye-dropper': '🎨',
                        'commentlist-alt': '💬',
                        'power-off': '⏻',
                        'lock': '🔒',
                        'unlock': '🔓',
                        'refresh': '🔄',
                        'eraser': '🧹',
                        'dashboard': '📊',
                        'logger': '📝',
                        'settings': '⚙️',
                        'options': '🔧'
                    };

                    // 3. Comprehensive icon fixing function
                    function fixAllIcons() {
                        console.log('🎨 Fixing all icons comprehensively...');

                        // Method 1: Replace text content
                        const allElements = document.querySelectorAll('*');
                        allElements.forEach(element => {
                            if (element.children.length === 0) { // Only leaf elements
                                let text = element.textContent?.trim();
                                if (text && iconMap[text]) {
                                    element.textContent = iconMap[text];
                                    element.style.fontSize = '16px';
                                    console.log('🎨 Replaced text icon: ' + text + ' → ' + iconMap[text]);
                                }
                            }

                            // Method 2: Check class names
                            if (element.className && typeof element.className === 'string') {
                                const classes = element.className.split(' ');
                                for (const className of classes) {
                                    if (className.startsWith('fa-')) {
                                        const iconName = className.substring(3);
                                        if (iconMap[iconName]) {
                                            element.textContent = iconMap[iconName];
                                            element.style.fontFamily = 'system-ui, -apple-system, sans-serif';
                                            element.style.fontSize = '16px';
                                            console.log('🎨 Replaced FA class icon: ' + iconName + ' → ' + iconMap[iconName]);
                                        }
                                    }
                                }
                            }

                            // Method 3: Check data attributes
                            const dataI18n = element.getAttribute('data-i18n');
                            if (dataI18n && iconMap[dataI18n]) {
                                element.textContent = iconMap[dataI18n];
                                console.log('🎨 Replaced data-i18n icon: ' + dataI18n + ' → ' + iconMap[dataI18n]);
                            }
                        });

                        // Method 4: Force specific uBlock elements
                        const specificSelectors = [
                            '[data-i18n="popupTipLock"]',
                            '[data-i18n="popupTipRefresh"]',
                            '[data-i18n="popupTipEraser"]',
                            '.fa-film',
                            '.fa-bolt',
                            '.fa-cogs'
                        ];

                        specificSelectors.forEach(selector => {
                            const elements = document.querySelectorAll(selector);
                            elements.forEach(element => {
                                const dataI18n = element.getAttribute('data-i18n');
                                if (dataI18n) {
                                    // Map specific uBlock data-i18n values
                                    if (dataI18n.includes('Lock')) {
                                        element.textContent = '🔒';
                                    } else if (dataI18n.includes('Refresh')) {
                                        element.textContent = '🔄';
                                    } else if (dataI18n.includes('Eraser')) {
                                        element.textContent = '🧹';
                                    }
                                    console.log('🎯 Fixed specific uBlock element: ' + selector);
                                }
                            });
                        });
                    }

                    // 4. Process modules and fix icons
                    const moduleScripts = document.querySelectorAll('script[type="module"]');
                    console.log('🔍 Processing ' + moduleScripts.length + ' module scripts...');

                    let processedModules = 0;
                    const totalModules = moduleScripts.length;

                    function onModulesComplete() {
                        console.log('✅ All modules processed, fixing icons...');
                        setTimeout(() => {
                            fixAllIcons();

                            // Fix icons again after a delay to catch dynamic content
                            setTimeout(fixAllIcons, 500);
                            setTimeout(fixAllIcons, 1000);
                        }, 100);
                    }

                    if (totalModules === 0) {
                        onModulesComplete();
                    } else {
                        moduleScripts.forEach((moduleScript, index) => {
                            try {
                                if (moduleScript.src) {
                                    const xhr = new XMLHttpRequest();
                                    xhr.open('GET', moduleScript.src, true);
                                    xhr.onload = function() {
                                        if (xhr.status === 200 || xhr.status === 0) {
                                            try {
                                                const regularScript = document.createElement('script');
                                                regularScript.textContent = xhr.responseText;
                                                regularScript.setAttribute('data-alto-converted-module', moduleScript.src);
                                                document.head.appendChild(regularScript);
                                                console.log('✅ Module ' + index + ' executed');
                                            } catch (execError) {
                                                console.error('❌ Error executing module ' + index + ':', execError);
                                            }
                                        }

                                        processedModules++;
                                        if (processedModules >= totalModules) {
                                            onModulesComplete();
                                        }
                                    };
                                    xhr.onerror = function() {
                                        processedModules++;
                                        if (processedModules >= totalModules) {
                                            onModulesComplete();
                                        }
                                    };
                                    xhr.send();
                                } else {
                                    // Inline module
                                    try {
                                        const regularScript = document.createElement('script');
                                        regularScript.textContent = moduleScript.textContent;
                                        document.head.appendChild(regularScript);
                                        console.log('✅ Inline module ' + index + ' executed');
                                    } catch (execError) {
                                        console.error('❌ Error executing inline module ' + index + ':', execError);
                                    }

                                    processedModules++;
                                    if (processedModules >= totalModules) {
                                        onModulesComplete();
                                    }
                                }
                            } catch (error) {
                                console.error('❌ Error processing module ' + index + ':', error);
                                processedModules++;
                                if (processedModules >= totalModules) {
                                    onModulesComplete();
                                }
                            }
                        });
                    }

                    return 'complete-fix-with-icons-initiated';
                } catch (error) {
                    console.error('❌ [\(extensionName)] Complete fix error:', error);
                    return 'complete-fix-error: ' + error.message;
                }
            })();
        """

        webView.evaluateJavaScript(completeFixScript) { _, error in
            if let error {
                self.logger.error("❌ [\(self.extensionName)] Complete fix failed: \(error.localizedDescription)")
            } else {
                // self.logger.info("✅ [\(self.extensionName)] Complete fix executed: \(result ?? "unknown")")
            }
        }
    }
}

// MARK: - WebViewRepresentable

struct WebViewRepresentable: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
}
