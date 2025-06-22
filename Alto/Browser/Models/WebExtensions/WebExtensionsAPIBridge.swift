//
//  WebExtensionsAPIBridge.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Foundation
import os.log
import UserNotifications
import WebKit

// MARK: - WebExtensionsAPIBridge

@MainActor
final class WebExtensionsAPIBridge: NSObject, WKScriptMessageHandler {
    static let shared = WebExtensionsAPIBridge()

    private let extensionManager = ExtensionManager.shared
    private let storageManager = ExtensionStorageManager()
    private let logger = Logger(subsystem: "Alto.WebExtensions", category: "APIBridge")

    // Active WebViews and their contexts
    private var activeWebViews: Set<WKWebView> = []
    private var webViewContexts: [WKWebView: ExtensionContext] = [:]

    // Event listeners and callbacks
    private var eventListeners: [String: [EventListener]] = [:]
    private var pendingCallbacks: [String: APICallback] = [:]
    private var callbackCounter = 0

    // Tab management
    private var tabIdCounter = 1
    private var webViewToTabId: [WKWebView: Int] = [:]
    private var tabIdToWebView: [Int: WKWebView] = [:]

    override init() {
        super.init()
        setupNotifications()
        logger.info("WebExtensions API Bridge initialized")
    }

    // MARK: - WebView Management

    func configureWebView(_ webView: WKWebView, for extensionId: String? = nil) {
        activeWebViews.insert(webView)

        let tabId = tabIdCounter
        tabIdCounter += 1

        webViewToTabId[webView] = tabId
        tabIdToWebView[tabId] = webView

        let context = ExtensionContext(
            extensionId: extensionId,
            tabId: tabId,
            webView: webView
        )
        webViewContexts[webView] = context

        // Add message handlers
        let userContentController = webView.configuration.userContentController
        userContentController.add(self, name: "altoExtensionAPI")

        // Inject the API bridge
        injectAPIBridge(into: webView)

        logger.info("Configured WebView for extension context - Tab ID: \(tabId)")
    }

    func removeWebView(_ webView: WKWebView) {
        guard let tabId = webViewToTabId[webView] else { return }

        activeWebViews.remove(webView)
        webViewContexts.removeValue(forKey: webView)
        webViewToTabId.removeValue(forKey: webView)
        tabIdToWebView.removeValue(forKey: tabId)

        logger.info("Removed WebView - Tab ID: \(tabId)")
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let webView = message.webView,
              let context = webViewContexts[webView],
              let body = message.body as? [String: Any] else {
            logger.error("Invalid message received")
            return
        }

        handleAPICall(body, context: context, webView: webView)
    }

    // MARK: - API Call Handling

    private func handleAPICall(_ body: [String: Any], context: ExtensionContext, webView: WKWebView) {
        guard let api = body["api"] as? String,
              let method = body["method"] as? String else {
            logger.error("Missing API or method in call")
            return
        }

        let params = body["params"] as? [String: Any] ?? [:]
        let callbackId = body["callbackId"] as? String

        logger.info("API Call: \(api).\(method)")

        // Create callback handler
        let callback = APICallback(id: callbackId, webView: webView)
        if let callbackId {
            pendingCallbacks[callbackId] = callback
        }

        // Route to appropriate handler
        switch api {
        case "chrome.tabs",
             "browser.tabs":
            handleTabsAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.runtime",
             "browser.runtime":
            handleRuntimeAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.storage",
             "browser.storage":
            handleStorageAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.webRequest",
             "browser.webRequest":
            handleWebRequestAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.contextMenus",
             "browser.contextMenus":
            handleContextMenusAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.notifications",
             "browser.notifications":
            handleNotificationsAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.action",
             "chrome.browserAction",
             "browser.action",
             "browser.browserAction":
            handleActionAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.scripting",
             "browser.scripting":
            handleScriptingAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.permissions",
             "browser.permissions":
            handlePermissionsAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.cookies",
             "browser.cookies":
            handleCookiesAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.history",
             "browser.history":
            handleHistoryAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.bookmarks",
             "browser.bookmarks":
            handleBookmarksAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.webNavigation",
             "browser.webNavigation":
            handleWebNavigationAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.declarativeNetRequest",
             "browser.declarativeNetRequest":
            handleDeclarativeNetRequestAPI(method: method, params: params, context: context, callback: callback)
        case "chrome.i18n",
             "browser.i18n":
            handleI18nAPI(method: method, params: params, context: context, callback: callback)
        default:
            callback.error("Unsupported API: \(api)")
        }
    }

    // MARK: - Tabs API

    private func handleTabsAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "query":
            let queryInfo = params["queryInfo"] as? [String: Any] ?? [:]
            let tabs = queryTabs(queryInfo: queryInfo)
            callback.success(tabs)

        case "create":
            guard let createProperties = params["createProperties"] as? [String: Any] else {
                callback.error("Invalid createProperties")
                return
            }
            createTab(properties: createProperties, callback: callback)

        case "update":
            guard let tabId = params["tabId"] as? Int,
                  let updateProperties = params["updateProperties"] as? [String: Any] else {
                callback.error("Invalid parameters")
                return
            }
            updateTab(tabId: tabId, properties: updateProperties, callback: callback)

        case "remove":
            guard let tabIds = params["tabIds"] as? [Int] else {
                callback.error("Invalid tabIds")
                return
            }
            removeTabs(tabIds: tabIds, callback: callback)

        case "get":
            guard let tabId = params["tabId"] as? Int else {
                callback.error("Invalid tabId")
                return
            }
            getTab(tabId: tabId, callback: callback)

        case "executeScript":
            let tabId = params["tabId"] as? Int
            guard let details = params["details"] as? [String: Any] else {
                callback.error("Invalid script details")
                return
            }
            executeScript(tabId: tabId, details: details, context: context, callback: callback)

        case "insertCSS":
            let tabId = params["tabId"] as? Int
            guard let details = params["details"] as? [String: Any] else {
                callback.error("Invalid CSS details")
                return
            }
            insertCSS(tabId: tabId, details: details, callback: callback)

        case "sendMessage":
            guard let tabId = params["tabId"] as? Int,
                  let message = params["message"] else {
                callback.error("Invalid parameters")
                return
            }
            sendMessageToTab(tabId: tabId, message: message, callback: callback)

        case "reload":
            let tabId = params["tabId"] as? Int
            let reloadProperties = params["reloadProperties"] as? [String: Any] ?? [:]
            reloadTab(tabId: tabId, properties: reloadProperties, callback: callback)

        default:
            callback.error("Unknown tabs method: \(method)")
        }
    }

    // MARK: - Runtime API

    private func handleRuntimeAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "sendMessage":
            guard let message = params["message"] else {
                callback.error("Invalid message")
                return
            }
            sendRuntimeMessage(message: message, context: context, callback: callback)

        case "getManifest":
            getManifest(context: context, callback: callback)

        case "getURL":
            guard let path = params["path"] as? String else {
                callback.error("Invalid path")
                return
            }
            let url = getExtensionURL(path: path, context: context)
            callback.success(["url": url])

        case "getPlatformInfo":
            let platformInfo = getPlatformInfo()
            callback.success(platformInfo)

        case "getBrowserInfo":
            let browserInfo = getBrowserInfo()
            callback.success(browserInfo)

        case "openOptionsPage":
            openOptionsPage(context: context, callback: callback)

        case "setUninstallURL":
            let url = params["url"] as? String
            setUninstallURL(url: url, context: context, callback: callback)

        case "reload":
            reloadExtension(context: context, callback: callback)

        default:
            callback.error("Unknown runtime method: \(method)")
        }
    }

    // MARK: - Storage API

    private func handleStorageAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        guard let extensionId = context.extensionId else {
            callback.error("No extension context")
            return
        }

        let area = StorageArea(rawValue: params["area"] as? String ?? "local") ?? .local

        switch method {
        case "get":
            let keys = parseStorageKeys(params["keys"])
            let result = storageManager.get(extensionId: extensionId, area: area, keys: keys)
            callback.success(result)

        case "set":
            guard let items = params["items"] as? [String: Any] else {
                callback.error("Invalid items")
                return
            }
            do {
                try storageManager.set(extensionId: extensionId, area: area, items: items)
                callback.success(nil)
            } catch {
                callback.error(error.localizedDescription)
            }

        case "remove":
            guard let keys = params["keys"] as? [String] else {
                callback.error("Invalid keys")
                return
            }
            storageManager.remove(extensionId: extensionId, area: area, keys: keys)
            callback.success(nil)

        case "clear":
            storageManager.clear(extensionId: extensionId, area: area)
            callback.success(nil)

        case "getBytesInUse":
            let keys = params["keys"] as? [String]
            let bytes = storageManager.getBytesInUse(extensionId: extensionId, area: area, keys: keys)
            callback.success(["bytesInUse": bytes])

        default:
            callback.error("Unknown storage method: \(method)")
        }
    }

    // MARK: - Web Request API

    private func handleWebRequestAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "addListener":
            guard let eventType = params["eventType"] as? String else {
                callback.error("Invalid eventType")
                return
            }
            addWebRequestListener(eventType: eventType, context: context, callback: callback)

        case "removeListener":
            guard let eventType = params["eventType"] as? String else {
                callback.error("Invalid eventType")
                return
            }
            removeWebRequestListener(eventType: eventType, context: context, callback: callback)

        default:
            callback.error("Unknown webRequest method: \(method)")
        }
    }

    // MARK: - Context Menus API

    private func handleContextMenusAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "create":
            guard let createProperties = params["createProperties"] as? [String: Any] else {
                callback.error("Invalid createProperties")
                return
            }
            createContextMenu(properties: createProperties, context: context, callback: callback)

        case "update":
            guard let id = params["id"] as? String,
                  let updateProperties = params["updateProperties"] as? [String: Any] else {
                callback.error("Invalid parameters")
                return
            }
            updateContextMenu(id: id, properties: updateProperties, context: context, callback: callback)

        case "remove":
            guard let menuItemId = params["menuItemId"] as? String else {
                callback.error("Invalid menuItemId")
                return
            }
            removeContextMenu(id: menuItemId, context: context, callback: callback)

        case "removeAll":
            removeAllContextMenus(context: context, callback: callback)

        default:
            callback.error("Unknown contextMenus method: \(method)")
        }
    }

    // MARK: - Notifications API

    private func handleNotificationsAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "create":
            let notificationId = params["notificationId"] as? String ?? "notification_\(Date().timeIntervalSince1970)"
            guard let options = params["options"] as? [String: Any] else {
                callback.error("Invalid options")
                return
            }
            createNotification(id: notificationId, options: options, callback: callback)

        case "update":
            guard let notificationId = params["notificationId"] as? String,
                  let options = params["options"] as? [String: Any] else {
                callback.error("Invalid parameters")
                return
            }
            updateNotification(id: notificationId, options: options, callback: callback)

        case "clear":
            guard let notificationId = params["notificationId"] as? String else {
                callback.error("Invalid notificationId")
                return
            }
            clearNotification(id: notificationId, callback: callback)

        case "getAll":
            getAllNotifications(callback: callback)

        default:
            callback.error("Unknown notifications method: \(method)")
        }
    }

    // MARK: - Action API

    private func handleActionAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "setIcon":
            let details = params["details"] as? [String: Any] ?? [:]
            setActionIcon(details: details, context: context, callback: callback)

        case "setTitle":
            let details = params["details"] as? [String: Any] ?? [:]
            setActionTitle(details: details, context: context, callback: callback)

        case "setBadgeText":
            let details = params["details"] as? [String: Any] ?? [:]
            setActionBadgeText(details: details, context: context, callback: callback)

        case "setBadgeBackgroundColor":
            let details = params["details"] as? [String: Any] ?? [:]
            setActionBadgeBackgroundColor(details: details, context: context, callback: callback)

        case "setPopup":
            let details = params["details"] as? [String: Any] ?? [:]
            setActionPopup(details: details, context: context, callback: callback)

        default:
            callback.error("Unknown action method: \(method)")
        }
    }

    // MARK: - Scripting API

    private func handleScriptingAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "executeScript":
            guard let injection = params["injection"] as? [String: Any] else {
                callback.error("Invalid injection")
                return
            }
            executeScriptV3(injection: injection, context: context, callback: callback)

        case "insertCSS":
            guard let injection = params["injection"] as? [String: Any] else {
                callback.error("Invalid injection")
                return
            }
            insertCSSV3(injection: injection, context: context, callback: callback)

        case "removeCSS":
            guard let injection = params["injection"] as? [String: Any] else {
                callback.error("Invalid injection")
                return
            }
            removeCSSV3(injection: injection, context: context, callback: callback)

        default:
            callback.error("Unknown scripting method: \(method)")
        }
    }

    // MARK: - Permissions API

    private func handlePermissionsAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "contains":
            guard let permissions = params["permissions"] as? [String: Any] else {
                callback.error("Invalid permissions")
                return
            }
            let result = checkPermissions(permissions: permissions, context: context)
            callback.success(["result": result])

        case "request":
            guard let permissions = params["permissions"] as? [String: Any] else {
                callback.error("Invalid permissions")
                return
            }
            requestPermissions(permissions: permissions, context: context, callback: callback)

        case "remove":
            guard let permissions = params["permissions"] as? [String: Any] else {
                callback.error("Invalid permissions")
                return
            }
            removePermissions(permissions: permissions, context: context, callback: callback)

        default:
            callback.error("Unknown permissions method: \(method)")
        }
    }

    // MARK: - Stub API Handlers (implement as needed)

    private func handleCookiesAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        // TODO: Implement cookies API
        callback.success(["message": "Cookies API not yet implemented"])
    }

    private func handleHistoryAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        // TODO: Implement history API
        callback.success(["message": "History API not yet implemented"])
    }

    private func handleBookmarksAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        // TODO: Implement bookmarks API
        callback.success(["message": "Bookmarks API not yet implemented"])
    }

    private func handleWebNavigationAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        // TODO: Implement web navigation API
        callback.success(["message": "WebNavigation API not yet implemented"])
    }

    private func handleDeclarativeNetRequestAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        // TODO: Implement declarative net request API
        callback.success(["message": "DeclarativeNetRequest API not yet implemented"])
    }

    private func handleI18nAPI(
        method: String,
        params: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        switch method {
        case "getMessage":
            guard let messageName = params["messageName"] as? String else {
                callback.error("Invalid messageName")
                return
            }
            let substitutions = params["substitutions"]
            let message = getI18nMessage(messageName: messageName, substitutions: substitutions)
            callback.success(["message": message])

        case "getUILanguage":
            callback.success(["language": Locale.current.languageCode ?? "en"])

        default:
            callback.error("Unknown i18n method: \(method)")
        }
    }

    // MARK: - API Implementation Methods

    private func queryTabs(queryInfo: [String: Any]) -> [[String: Any]] {
        var tabs: [[String: Any]] = []

        for (index, webView) in activeWebViews.enumerated() {
            guard let tabId = webViewToTabId[webView] else { continue }

            let tab: [String: Any] = [
                "id": tabId,
                "index": index,
                "windowId": 1,
                "highlighted": index == 0,
                "active": index == 0,
                "pinned": false,
                "audible": false,
                "discarded": false,
                "autoDiscardable": true,
                "mutedInfo": ["muted": false],
                "url": webView.url?.absoluteString ?? "about:blank",
                "title": webView.title ?? "New Tab",
                "favIconUrl": "",
                "status": "complete",
                "incognito": false,
                "width": Int(webView.frame.width),
                "height": Int(webView.frame.height)
            ]

            // Apply filters
            var matches = true

            if let active = queryInfo["active"] as? Bool {
                if (tab["active"] as? Bool) != active {
                    matches = false
                }
            }

            if let url = queryInfo["url"] as? String {
                if (tab["url"] as? String) != url {
                    matches = false
                }
            }

            if matches {
                tabs.append(tab)
            }
        }

        return tabs
    }

    private func createTab(properties: [String: Any], callback: APICallback) {
        let url = properties["url"] as? String ?? "about:blank"
        let active = properties["active"] as? Bool ?? true

        // TODO: Integrate with Alto's tab manager to actually create a tab
        logger.info("Extension requested new tab: \(url), active: \(active)")

        let newTab: [String: Any] = [
            "id": tabIdCounter,
            "index": activeWebViews.count,
            "windowId": 1,
            "highlighted": active,
            "active": active,
            "pinned": false,
            "url": url,
            "title": "New Tab",
            "status": "loading"
        ]

        tabIdCounter += 1
        callback.success(newTab)
    }

    private func updateTab(tabId: Int, properties: [String: Any], callback: APICallback) {
        guard let webView = tabIdToWebView[tabId] else {
            callback.error("Tab not found")
            return
        }

        if let url = properties["url"] as? String,
           let targetURL = URL(string: url) {
            let request = URLRequest(url: targetURL)
            webView.load(request)
            logger.info("Updated tab \(tabId) to URL: \(url)")
        }

        callback.success(["success": true])
    }

    private func removeTabs(tabIds: [Int], callback: APICallback) {
        // TODO: Integrate with Alto's tab manager to actually close tabs
        logger.info("Extension requested to close tabs: \(tabIds)")
        callback.success(["success": true])
    }

    private func getTab(tabId: Int, callback: APICallback) {
        guard let webView = tabIdToWebView[tabId] else {
            callback.error("Tab not found")
            return
        }

        let tab: [String: Any] = [
            "id": tabId,
            "index": 0,
            "windowId": 1,
            "active": true,
            "url": webView.url?.absoluteString ?? "about:blank",
            "title": webView.title ?? "Tab",
            "status": "complete"
        ]

        callback.success(tab)
    }

    private func executeScript(tabId: Int?, details: [String: Any], context: ExtensionContext, callback: APICallback) {
        let targetWebView: WKWebView

        if let tabId {
            guard let webView = tabIdToWebView[tabId] else {
                callback.error("Tab not found")
                return
            }
            targetWebView = webView
        } else {
            targetWebView = context.webView
        }

        if let code = details["code"] as? String {
            targetWebView.evaluateJavaScript(code) { result, error in
                if let error {
                    callback.error(error.localizedDescription)
                } else {
                    callback.success([result ?? NSNull()])
                }
            }
        } else if let file = details["file"] as? String {
            // TODO: Load and execute script file
            callback.error("Script file execution not yet implemented")
        } else {
            callback.error("No code or file specified")
        }
    }

    private func insertCSS(tabId: Int?, details: [String: Any], callback: APICallback) {
        let targetWebView: WKWebView

        if let tabId {
            guard let webView = tabIdToWebView[tabId] else {
                callback.error("Tab not found")
                return
            }
            targetWebView = webView
        } else {
            callback.error("No target webview")
            return
        }

        if let css = details["css"] as? String {
            let script = """
                (function() {
                    var style = document.createElement('style');
                    style.textContent = `\(css.replacingOccurrences(of: "`", with: "\\`"))`;
                    document.head.appendChild(style);
                })();
            """

            targetWebView.evaluateJavaScript(script) { _, error in
                if let error {
                    callback.error(error.localizedDescription)
                } else {
                    callback.success(["success": true])
                }
            }
        } else {
            callback.error("No CSS specified")
        }
    }

    private func sendMessageToTab(tabId: Int, message: Any, callback: APICallback) {
        // TODO: Implement inter-tab messaging
//        logger.info("Message to tab \(tabId): \(message)")
        callback.success(["success": true])
    }

    private func reloadTab(tabId: Int?, properties: [String: Any], callback: APICallback) {
        if let tabId,
           let webView = tabIdToWebView[tabId] {
            webView.reload()
            logger.info("Reloaded tab \(tabId)")
        }
        callback.success(["success": true])
    }

    private func sendRuntimeMessage(message: Any, context: ExtensionContext, callback: APICallback) {
        // Handle extension-specific messages
        if let messageDict = message as? [String: Any] {
            // Handle uBlock Origin specific messages
            if let what = messageDict["what"] as? String {
                switch what {
                case "getPopupData":
                    let popupData: [String: Any] = [
                        "tabId": context.tabId,
                        "tabURL": context.webView.url?.absoluteString ?? "about:blank",
                        "tabHostname": context.webView.url?.host ?? "localhost",
                        "tabTitle": context.webView.title ?? "Page",
                        "globalBlockedRequestCount": 1234,
                        "pageBlockedRequestCount": 15,
                        "globalAllowedRequestCount": 5678,
                        "pageAllowedRequestCount": 42,
                        "netFilteringSwitch": true,
                        "cosmeticFilteringSwitch": true,
                        "firewallPaneMinimized": true,
                        "popupBlockedCount": 15,
                        "advancedUserEnabled": false
                    ]
                    callback.success(popupData)
                    return

                case "getScriptlets":
                    callback.success([])
                    return

                default:
                    break
                }
            }

            // Handle LocalCDN specific messages
            if let topic = messageDict["topic"] as? String {
                switch topic {
                case "popup:get-data":
                    let responseData: [String: Any] = [
                        "data": [
                            "amountInjected": 42,
                            "blocked": 15,
                            "status": "enabled",
                            "isExtensionEnabled": true
                        ],
                        "success": true
                    ]
                    callback.success(responseData)
                    return

                default:
                    break
                }
            }
        }

        callback.success(["success": true, "response": "Message received"])
    }

    private func getManifest(context: ExtensionContext, callback: APICallback) {
        guard let extensionId = context.extensionId,
              let webExtension = extensionManager.getExtensionInfo(id: extensionId) else {
            // Return fallback manifest
            let fallback: [String: Any] = [
                "manifest_version": 2,
                "name": "Extension",
                "version": "1.0.0"
            ]
            callback.success(fallback)
            return
        }

        let manifest = webExtension.manifest
        var manifestData: [String: Any] = [
            "manifest_version": manifest.manifestVersion,
            "name": manifest.name,
            "version": manifest.version,
            "description": manifest.description ?? ""
        ]

        if let permissions = manifest.permissions {
            manifestData["permissions"] = permissions
        }

        if let hostPermissions = manifest.hostPermissions {
            manifestData["host_permissions"] = hostPermissions
        }

        if let contentScripts = manifest.contentScripts {
            manifestData["content_scripts"] = contentScripts.map { cs in
                var scriptData: [String: Any] = [
                    "matches": cs.matches,
                    "js": cs.js,
                    "run_at": cs.runAt ?? "document_idle"
                ]
                if let css = cs.css {
                    scriptData["css"] = css
                }
                return scriptData
            }
        }

        callback.success(manifestData)
    }

    private func getExtensionURL(path: String, context: ExtensionContext) -> String {
        "chrome-extension://\(context.extensionId ?? "unknown")/\(path)"
    }

    private func getPlatformInfo() -> [String: Any] {
        [
            "os": "mac",
            "arch": "arm64",
            "nacl_arch": "arm"
        ]
    }

    private func getBrowserInfo() -> [String: Any] {
        [
            "name": "Alto",
            "vendor": "Alto",
            "version": "1.0.0",
            "buildID": "20250621"
        ]
    }

    private func openOptionsPage(context: ExtensionContext, callback: APICallback) {
        // TODO: Open extension options page
        logger.info("Extension requested to open options page")
        callback.success(["success": true])
    }

    private func setUninstallURL(url: String?, context: ExtensionContext, callback: APICallback) {
        if let url {
            logger.info("Extension set uninstall URL: \(url)")
        }
        callback.success(["success": true])
    }

    private func reloadExtension(context: ExtensionContext, callback: APICallback) {
        guard let extensionId = context.extensionId else {
            callback.error("No extension context")
            return
        }

        Task {
            do {
                try await extensionManager.reloadExtension(id: extensionId)
                callback.success(["success": true])
            } catch {
                callback.error(error.localizedDescription)
            }
        }
    }

    private func parseStorageKeys(_ keys: Any?) -> StorageKeys {
        if keys == nil {
            .all
        } else if let keyString = keys as? String {
            .single(keyString)
        } else if let keyArray = keys as? [String] {
            .multiple(keyArray)
        } else if let keyDict = keys as? [String: Any] {
            .withDefaults(keyDict)
        } else {
            .all
        }
    }

    // MARK: - Notification Setup

    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error {
                self.logger.error("Notification permission error: \(error.localizedDescription)")
            } else {
                self.logger.info("Notification permissions granted: \(granted)")
            }
        }
    }

    // MARK: - Stub implementations for remaining methods

    private func addWebRequestListener(eventType: String, context: ExtensionContext, callback: APICallback) {
        logger.info("WebRequest listener added for: \(eventType)")
        callback.success(["success": true])
    }

    private func removeWebRequestListener(eventType: String, context: ExtensionContext, callback: APICallback) {
        logger.info("WebRequest listener removed for: \(eventType)")
        callback.success(["success": true])
    }

    private func createContextMenu(properties: [String: Any], context: ExtensionContext, callback: APICallback) {
        let menuId = properties["id"] as? String ?? UUID().uuidString
        logger.info("Context menu created: \(menuId)")
        callback.success(["menuItemId": menuId])
    }

    private func updateContextMenu(
        id: String,
        properties: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        callback.success(["success": true])
    }

    private func removeContextMenu(id: String, context: ExtensionContext, callback: APICallback) {
        callback.success(["success": true])
    }

    private func removeAllContextMenus(context: ExtensionContext, callback: APICallback) {
        callback.success(["success": true])
    }

    private func createNotification(id: String, options: [String: Any], callback: APICallback) {
        let title = options["title"] as? String ?? "Notification"
        let message = options["message"] as? String ?? ""

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error {
                    callback.error(error.localizedDescription)
                } else {
                    callback.success(["notificationId": id])
                }
            }
        }
    }

    private func updateNotification(id: String, options: [String: Any], callback: APICallback) {
        callback.success(["success": true])
    }

    private func clearNotification(id: String, callback: APICallback) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        callback.success(["wasCleared": true])
    }

    private func getAllNotifications(callback: APICallback) {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            DispatchQueue.main.async {
                let notificationData = notifications.reduce(into: [String: [String: Any]]()) { result, notification in
                    result[notification.request.identifier] = [
                        "title": notification.request.content.title,
                        "message": notification.request.content.body
                    ]
                }
                callback.success(notificationData)
            }
        }
    }

    private func setActionIcon(details: [String: Any], context: ExtensionContext, callback: APICallback) {
        callback.success(["success": true])
    }

    private func setActionTitle(details: [String: Any], context: ExtensionContext, callback: APICallback) {
        callback.success(["success": true])
    }

    private func setActionBadgeText(details: [String: Any], context: ExtensionContext, callback: APICallback) {
        callback.success(["success": true])
    }

    private func setActionBadgeBackgroundColor(
        details: [String: Any],
        context: ExtensionContext,
        callback: APICallback
    ) {
        callback.success(["success": true])
    }

    private func setActionPopup(details: [String: Any], context: ExtensionContext, callback: APICallback) {
        callback.success(["success": true])
    }

    private func executeScriptV3(injection: [String: Any], context: ExtensionContext, callback: APICallback) {
        // TODO: Implement manifest v3 scripting API
        callback.success(["success": true])
    }

    private func insertCSSV3(injection: [String: Any], context: ExtensionContext, callback: APICallback) {
        // TODO: Implement manifest v3 CSS injection
        callback.success(["success": true])
    }

    private func removeCSSV3(injection: [String: Any], context: ExtensionContext, callback: APICallback) {
        // TODO: Implement manifest v3 CSS removal
        callback.success(["success": true])
    }

    private func checkPermissions(permissions: [String: Any], context: ExtensionContext) -> Bool {
        // TODO: Implement permission checking
        true
    }

    private func requestPermissions(permissions: [String: Any], context: ExtensionContext, callback: APICallback) {
        // TODO: Implement permission requesting
        callback.success(["result": true])
    }

    private func removePermissions(permissions: [String: Any], context: ExtensionContext, callback: APICallback) {
        // TODO: Implement permission removal
        callback.success(["result": true])
    }

    private func getI18nMessage(messageName: String, substitutions: Any?) -> String {
        // Basic i18n implementation
        let translations: [String: String] = [
            "extensionName": "Extension",
            "popupBlockedCount": "Blocked",
            "popupTipDashboard": "Open the dashboard",
            "popupTipZapper": "Enter element zapper mode",
            "popupTipPicker": "Enter element picker mode",
            "popupTipLog": "Open logger"
        ]

        return translations[messageName] ?? messageName
    }

    // MARK: - JavaScript API Bridge Injection

    private func injectAPIBridge(into webView: WKWebView) {
        let apiScript = WKUserScript(
            source: generateAPIBridgeScript(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        webView.configuration.userContentController.addUserScript(apiScript)
    }

    public func generateAPIBridgeScript() -> String {
        """
        // Alto WebExtensions API Bridge
        (function() {
            'use strict';

            // Global state
            window._altoExtensionAPI = {
                callbackCounter: 0,
                callbacks: {}
            };

            function generateCallbackId() {
                return 'callback_' + (++window._altoExtensionAPI.callbackCounter);
            }

            function makeAPICall(api, method, params, callback) {
                const callbackId = callback ? generateCallbackId() : null;

                if (callback && callbackId) {
                    window._altoExtensionAPI.callbacks[callbackId] = callback;
                }

                const message = {
                    api: api,
                    method: method,
                    params: params || {},
                    callbackId: callbackId
                };

                try {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.altoExtensionAPI) {
                        window.webkit.messageHandlers.altoExtensionAPI.postMessage(message);
                    } else {
                        console.warn('Alto Extension API not available');
                        if (callback) {
                            setTimeout(() => callback(null), 0);
                        }
                    }
                } catch (e) {
                    console.error('Failed to call API:', api, method, e);
                    if (callback) {
                        setTimeout(() => callback(null), 0);
                    }
                }
            }

            // Response handler
            window._altoHandleAPIResponse = function(callbackId, result, error) {
                const callback = window._altoExtensionAPI.callbacks[callbackId];
                if (callback) {
                    delete window._altoExtensionAPI.callbacks[callbackId];
                    try {
                        if (error) {
                            console.error('API Error:', error);
                            callback(null);
                        } else {
                            callback(result);
                        }
                    } catch (e) {
                        console.error('Callback error:', e);
                    }
                }
            };

            // Chrome/Browser API Implementation
            window.chrome = window.chrome || {};
            window.browser = window.browser || window.chrome;

            // Tabs API
            window.chrome.tabs = {
                query: function(queryInfo, callback) {
                    makeAPICall('chrome.tabs', 'query', {queryInfo}, callback);
                },
                create: function(createProperties, callback) {
                    makeAPICall('chrome.tabs', 'create', {createProperties}, callback);
                },
                update: function(tabId, updateProperties, callback) {
                    makeAPICall('chrome.tabs', 'update', {tabId, updateProperties}, callback);
                },
                remove: function(tabIds, callback) {
                    makeAPICall('chrome.tabs', 'remove', {tabIds}, callback);
                },
                get: function(tabId, callback) {
                    makeAPICall('chrome.tabs', 'get', {tabId}, callback);
                },
                executeScript: function(tabId, details, callback) {
                    if (typeof tabId === 'object') {
                        callback = details;
                        details = tabId;
                        tabId = null;
                    }
                    makeAPICall('chrome.tabs', 'executeScript', {tabId, details}, callback);
                },
                insertCSS: function(tabId, details, callback) {
                    if (typeof tabId === 'object') {
                        callback = details;
                        details = tabId;
                        tabId = null;
                    }
                    makeAPICall('chrome.tabs', 'insertCSS', {tabId, details}, callback);
                },
                sendMessage: function(tabId, message, options, callback) {
                    if (typeof options === 'function') {
                        callback = options;
                        options = {};
                    }
                    makeAPICall('chrome.tabs', 'sendMessage', {tabId, message, options}, callback);
                },
                reload: function(tabId, reloadProperties, callback) {
                    if (typeof tabId === 'object') {
                        callback = reloadProperties;
                        reloadProperties = tabId;
                        tabId = null;
                    }
                    if (typeof reloadProperties === 'function') {
                        callback = reloadProperties;
                        reloadProperties = {};
                    }
                    makeAPICall('chrome.tabs', 'reload', {tabId, reloadProperties}, callback);
                },
                onUpdated: {
                    addListener: function(callback) { /* TODO */ },
                    removeListener: function(callback) { /* TODO */ }
                },
                onActivated: {
                    addListener: function(callback) { /* TODO */ },
                    removeListener: function(callback) { /* TODO */ }
                }
            };

            // Runtime API
            window.chrome.runtime = {
                sendMessage: function(message, options, callback) {
                    if (typeof options === 'function') {
                        callback = options;
                        options = {};
                    }
                    makeAPICall('chrome.runtime', 'sendMessage', {message, options}, callback);
                },
                getManifest: function() {
                    // Synchronous call - cached data
                    return window._altoManifestCache || {
                        manifest_version: 2,
                        name: 'Extension',
                        version: '1.0.0'
                    };
                },
                getURL: function(path) {
                    return 'chrome-extension://alto-extension/' + path;
                },
                getPlatformInfo: function(callback) {
                    makeAPICall('chrome.runtime', 'getPlatformInfo', {}, callback);
                },
                getBrowserInfo: function(callback) {
                    makeAPICall('chrome.runtime', 'getBrowserInfo', {}, callback);
                },
                openOptionsPage: function(callback) {
                    makeAPICall('chrome.runtime', 'openOptionsPage', {}, callback);
                },
                setUninstallURL: function(url, callback) {
                    makeAPICall('chrome.runtime', 'setUninstallURL', {url}, callback);
                },
                reload: function() {
                    makeAPICall('chrome.runtime', 'reload', {});
                },
                id: 'alto-extension',
                lastError: undefined,
                onMessage: {
                    addListener: function(callback) { /* TODO */ },
                    removeListener: function(callback) { /* TODO */ }
                },
                onInstalled: {
                    addListener: function(callback) {
                        setTimeout(() => {
                            try {
                                callback({reason: 'install'});
                            } catch (e) {
                                console.error('onInstalled callback error:', e);
                            }
                        }, 100);
                    },
                    removeListener: function(callback) { /* TODO */ }
                }
            };

            // Storage API
            window.chrome.storage = {
                local: {
                    get: function(keys, callback) {
                        makeAPICall('chrome.storage', 'get', {keys, area: 'local'}, callback);
                    },
                    set: function(items, callback) {
                        makeAPICall('chrome.storage', 'set', {items, area: 'local'}, callback);
                    },
                    remove: function(keys, callback) {
                        makeAPICall('chrome.storage', 'remove', {keys, area: 'local'}, callback);
                    },
                    clear: function(callback) {
                        makeAPICall('chrome.storage', 'clear', {area: 'local'}, callback);
                    },
                    getBytesInUse: function(keys, callback) {
                        makeAPICall('chrome.storage', 'getBytesInUse', {keys, area: 'local'}, callback);
                    }
                },
                sync: {
                    get: function(keys, callback) {
                        makeAPICall('chrome.storage', 'get', {keys, area: 'sync'}, callback);
                    },
                    set: function(items, callback) {
                        makeAPICall('chrome.storage', 'set', {items, area: 'sync'}, callback);
                    },
                    remove: function(keys, callback) {
                        makeAPICall('chrome.storage', 'remove', {keys, area: 'sync'}, callback);
                    },
                    clear: function(callback) {
                        makeAPICall('chrome.storage', 'clear', {area: 'sync'}, callback);
                    },
                    getBytesInUse: function(keys, callback) {
                        makeAPICall('chrome.storage', 'getBytesInUse', {keys, area: 'sync'}, callback);
                    }
                }
            };

            // WebRequest API
            window.chrome.webRequest = {
                onBeforeRequest: {
                    addListener: function(callback, filter, extraInfoSpec) {
                        makeAPICall('chrome.webRequest', 'addListener', {
                            eventType: 'onBeforeRequest',
                            filter: filter,
                            extraInfoSpec: extraInfoSpec
                        });
                    },
                    removeListener: function(callback) {
                        makeAPICall('chrome.webRequest', 'removeListener', {
                            eventType: 'onBeforeRequest'
                        });
                    }
                },
                onBeforeSendHeaders: {
                    addListener: function(callback, filter, extraInfoSpec) {
                        makeAPICall('chrome.webRequest', 'addListener', {
                            eventType: 'onBeforeSendHeaders',
                            filter: filter,
                            extraInfoSpec: extraInfoSpec
                        });
                    },
                    removeListener: function(callback) {
                        makeAPICall('chrome.webRequest', 'removeListener', {
                            eventType: 'onBeforeSendHeaders'
                        });
                    }
                }
            };

            // Context Menus API
            window.chrome.contextMenus = {
                create: function(createProperties, callback) {
                    makeAPICall('chrome.contextMenus', 'create', {createProperties}, callback);
                },
                update: function(id, updateProperties, callback) {
                    makeAPICall('chrome.contextMenus', 'update', {id, updateProperties}, callback);
                },
                remove: function(menuItemId, callback) {
                    makeAPICall('chrome.contextMenus', 'remove', {menuItemId}, callback);
                },
                removeAll: function(callback) {
                    makeAPICall('chrome.contextMenus', 'removeAll', {}, callback);
                }
            };

            // Notifications API
            window.chrome.notifications = {
                create: function(notificationId, options, callback) {
                    if (typeof notificationId === 'object') {
                        callback = options;
                        options = notificationId;
                        notificationId = 'notification_' + Date.now();
                    }
                    makeAPICall('chrome.notifications', 'create', {notificationId, options}, callback);
                },
                update: function(notificationId, options, callback) {
                    makeAPICall('chrome.notifications', 'update', {notificationId, options}, callback);
                },
                clear: function(notificationId, callback) {
                    makeAPICall('chrome.notifications', 'clear', {notificationId}, callback);
                },
                getAll: function(callback) {
                    makeAPICall('chrome.notifications', 'getAll', {}, callback);
                }
            };

            // Action API (for both action and browserAction)
            const actionAPI = {
                setIcon: function(details, callback) {
                    makeAPICall('chrome.action', 'setIcon', {details}, callback);
                },
                setTitle: function(details, callback) {
                    makeAPICall('chrome.action', 'setTitle', {details}, callback);
                },
                setBadgeText: function(details, callback) {
                    makeAPICall('chrome.action', 'setBadgeText', {details}, callback);
                },
                setBadgeBackgroundColor: function(details, callback) {
                    makeAPICall('chrome.action', 'setBadgeBackgroundColor', {details}, callback);
                },
                setPopup: function(details, callback) {
                    makeAPICall('chrome.action', 'setPopup', {details}, callback);
                }
            };

            window.chrome.action = actionAPI;
            window.chrome.browserAction = actionAPI;

            // i18n API
            window.chrome.i18n = {
                getMessage: function(messageName, substitutions) {
                    // Synchronous call with fallback
                    const translations = {
                        'extensionName': 'Extension',
                        'popupBlockedCount': 'Blocked',
                        'popupTipDashboard': 'Open the dashboard',
                        'popupTipZapper': 'Enter element zapper mode',
                        'popupTipPicker': 'Enter element picker mode',
                        'popupTipLog': 'Open logger'
                    };

                    let result = translations[messageName] || messageName || '';

                    if (substitutions) {
                        if (Array.isArray(substitutions)) {
                            substitutions.forEach((sub, index) => {
                                result = result.replace(new RegExp('\\\\$' + (index + 1), 'g'), sub);
                            });
                        } else {
                            result = result.replace(/\\$1/g, substitutions);
                        }
                    }

                    return result;
                },
                getUILanguage: function() {
                    return navigator.language || 'en';
                }
            };

            // Additional stub APIs
            window.chrome.permissions = {
                contains: function(permissions, callback) {
                    makeAPICall('chrome.permissions', 'contains', {permissions}, callback);
                },
                request: function(permissions, callback) {
                    makeAPICall('chrome.permissions', 'request', {permissions}, callback);
                },
                remove: function(permissions, callback) {
                    makeAPICall('chrome.permissions', 'remove', {permissions}, callback);
                }
            };

            window.chrome.cookies = {
                get: function(details, callback) { if (callback) callback(null); },
                getAll: function(details, callback) { if (callback) callback([]); },
                set: function(details, callback) { if (callback) callback(null); },
                remove: function(details, callback) { if (callback) callback(null); }
            };

            window.chrome.history = {
                search: function(query, callback) { if (callback) callback([]); },
                addUrl: function(details, callback) { if (callback) callback(); },
                deleteUrl: function(details, callback) { if (callback) callback(); }
            };

            window.chrome.bookmarks = {
                get: function(idOrIdList, callback) { if (callback) callback([]); },
                getChildren: function(id, callback) { if (callback) callback([]); },
                create: function(bookmark, callback) { if (callback) callback(null); },
                remove: function(id, callback) { if (callback) callback(); }
            };

            // Initialize manifest cache
            makeAPICall('chrome.runtime', 'getManifest', {}, function(manifest) {
                if (manifest) {
                    window._altoManifestCache = manifest;
                }
            });

            console.log('🚀 Alto WebExtensions API Bridge loaded');

        })();
        """
    }
}

// MARK: - ExtensionContext

private struct ExtensionContext {
    let extensionId: String?
    let tabId: Int
    let webView: WKWebView
}

// MARK: - EventListener

private struct EventListener {
    let id: String
    let callback: (Any) -> ()
    let context: ExtensionContext
}

// MARK: - APICallback

private struct APICallback {
    let id: String?
    let webView: WKWebView

    func success(_ data: Any?) {
        guard let id else { return }

        let script: String
        if let data {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "null"
                script = "window._altoHandleAPIResponse('\(id)', \(jsonString), null);"
            } catch {
                script = "window._altoHandleAPIResponse('\(id)', null, 'JSON serialization error');"
            }
        } else {
            script = "window._altoHandleAPIResponse('\(id)', null, null);"
        }

        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func error(_ message: String) {
        guard let id else { return }

        let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
        let script = "window._altoHandleAPIResponse('\(id)', null, '\(escapedMessage)');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }
}
