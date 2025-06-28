//
//  ABBlockingManager.swift
//  Alto
//
//  Created by Kami on 26/06/2025.
//

import Foundation
import OpenADK
import OSLog
import SwiftUI
import WebKit

// MARK: - ABBlockingManager

/// Manages content blocking events and user interactions with blocked content
@MainActor
public final class ABBlockingManager: ObservableObject {
    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABBlockingManager")

    // MARK: - Singleton

    public static let shared = ABBlockingManager()

    // MARK: - Properties

    /// Currently blocked URLs awaiting user decision
    private var blockedSessions: [UUID: BlockedSession] = [:]

    /// Active popup states for each tab
    @Published public var activeBlockingPopups: [UUID: BlockingPopupState] = [:]

    /// One-time bypass URLs (for "Continue Once" functionality)
    private var oneTimeBypassURLs: Set<String> = []

    // MARK: - Initialization

    private init() {
        // logger.info("🛡️ ABBlockingManager initialized")
        setupNotificationListeners()
    }

    /// Set up notification listeners for content blocking events
    private func setupNotificationListeners() {
        // logger.info("🔔 Setting up notification listeners for content blocking")

        NotificationCenter.default.addObserver(
            forName: .contentWasBlocked,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // print("📥 ABBlockingManager received contentWasBlocked notification")

            guard let self else {
                print("❌ ABBlockingManager instance is nil")
                return
            }

            guard let webView = notification.object as? WKWebView else {
                print("❌ Notification object is not a WKWebView: \(String(describing: notification.object))")
                return
            }

            guard let userInfo = notification.userInfo else {
                print("❌ Notification has no userInfo")
                return
            }

            guard let url = userInfo["url"] as? URL else {
                print("❌ No URL in notification userInfo: \(userInfo)")
                return
            }

            guard let error = userInfo["error"] as? Error else {
                print("❌ No error in notification userInfo: \(userInfo)")
                return
            }

            print("✅ All notification parameters validated, calling handleContentBlocked")
            handleContentBlocked(webView: webView, url: url, error: error)
        }

        // logger.info("✅ Notification listeners set up successfully")
    }

    // MARK: - Public Methods

    /// Handle a content blocking error from WebKit
    /// - Parameters:
    ///   - webView: The WebView that encountered the blocking
    ///   - url: The blocked URL
    ///   - error: The WebKit error
    public func handleContentBlocked(webView: WKWebView, url: URL, error: Error) {
        let nsError = error as NSError

        // Only handle WebKit content blocker errors
        guard nsError.domain == "WebKitErrorDomain", nsError.code == 104 else {
            return
        }

        // Check if this URL has a one-time bypass
        if oneTimeBypassURLs.contains(url.absoluteString) {
            logger.info("🔓 One-time bypass found for URL: \(url)")
            oneTimeBypassURLs.remove(url.absoluteString)
            reloadWithoutBlocking(webView: webView, url: url)
            return
        }

        // Check if domain is permanently whitelisted
        let domain = url.host ?? url.absoluteString
        if ABManager.shared.isDomainWhitelisted(domain) {
            logger.info("✅ Domain is whitelisted, allowing: \(domain)")
            reloadWithoutBlocking(webView: webView, url: url)
            return
        }

        // Show blocking popup
        showBlockingPopup(for: webView, url: url)
    }

    /// Show the blocking popup for a specific WebView and URL
    /// - Parameters:
    ///   - webView: The WebView that was blocked
    ///   - url: The blocked URL
    public func showBlockingPopup(for webView: WKWebView, url: URL) {
        guard let webViewId = getWebViewId(webView) else {
            logger.warning("⚠️ Cannot get WebView ID for blocking popup")
            return
        }

        logger.info("🚫 Showing blocking popup for URL: \(url)")
        logger.info("🔍 WebView ID: \(webViewId)")

        let sessionId = UUID()
        let session = BlockedSession(
            id: sessionId,
            webView: webView,
            blockedURL: url,
            timestamp: Date()
        )

        blockedSessions[sessionId] = session

        let popupState = BlockingPopupState(
            sessionId: sessionId,
            blockedURL: url.absoluteString,
            blockerInfo: "Alto Ad Blocker",
            isVisible: true
        )

        activeBlockingPopups[webViewId] = popupState
//        logger.info("📱 Active popups count: \(self.activeBlockingPopups.count)")
//        logger.info("📱 Blocking popup shown for session: \(sessionId)")

        // Force UI update by posting to main thread
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    /// Handle user choosing to continue once
    /// - Parameter sessionId: The session ID of the blocked request
    public func continueOnce(sessionId: UUID) {
        guard let session = blockedSessions[sessionId] else {
            logger.warning("⚠️ Session not found for continue once: \(sessionId)")
            return
        }

        logger.info("🔓 User chose to continue once for: \(session.blockedURL)")

        // Add to one-time bypass list
        oneTimeBypassURLs.insert(session.blockedURL.absoluteString)

        // Hide popup
        hideBlockingPopup(sessionId: sessionId)

        // Reload the page
        reloadWithoutBlocking(webView: session.webView, url: session.blockedURL)

        // Clean up session
        blockedSessions.removeValue(forKey: sessionId)
    }

    /// Handle user choosing to whitelist permanently
    /// - Parameter sessionId: The session ID of the blocked request
    public func whitelistPermanently(sessionId: UUID) {
        guard let session = blockedSessions[sessionId] else {
            logger.warning("⚠️ Session not found for whitelist: \(sessionId)")
            return
        }

        let domain = session.blockedURL.host ?? session.blockedURL.absoluteString
        logger.info("✅ User chose to whitelist permanently: \(domain)")

        // Add to permanent whitelist
        ABManager.shared.addToWhitelist(domain: domain)

        // Hide popup
        hideBlockingPopup(sessionId: sessionId)

        // Reload the page
        reloadWithoutBlocking(webView: session.webView, url: session.blockedURL)

        // Clean up session
        blockedSessions.removeValue(forKey: sessionId)
    }

    /// Handle user choosing to cancel/go back
    /// - Parameter sessionId: The session ID of the blocked request
    public func cancelBlocking(sessionId: UUID) {
        guard let session = blockedSessions[sessionId] else {
            logger.warning("⚠️ Session not found for cancel: \(sessionId)")
            return
        }

        logger.info("↩️ User chose to go back for: \(session.blockedURL)")

        // Hide popup
        hideBlockingPopup(sessionId: sessionId)

        // Go back in history
        if session.webView.canGoBack {
            session.webView.goBack()
        } else {
            // Load a blank page or home page
            loadHomePage(webView: session.webView)
        }

        // Clean up session
        blockedSessions.removeValue(forKey: sessionId)
    }

    /// Check if a WebView has an active blocking popup
    /// - Parameter webView: The WebView to check
    /// - Returns: The popup state if active, nil otherwise
    public func getActivePopup(for webView: WKWebView) -> BlockingPopupState? {
        guard let webViewId = getWebViewId(webView) else { return nil }
        return activeBlockingPopups[webViewId]
    }

    /// Hide all blocking popups for a specific WebView
    /// - Parameter webView: The WebView to clear popups for
    public func hideAllPopups(for webView: WKWebView) {
        guard let webViewId = getWebViewId(webView) else { return }

        if let popupState = activeBlockingPopups[webViewId] {
            logger.info("🙈 Hiding all popups for WebView: \(webViewId)")

            // Clean up associated session
            blockedSessions.removeValue(forKey: popupState.sessionId)
        }

        activeBlockingPopups.removeValue(forKey: webViewId)
    }

    // MARK: - Private Methods

    /// Hide the blocking popup for a specific session
    /// - Parameter sessionId: The session ID to hide
    private func hideBlockingPopup(sessionId: UUID) {
        // Find and remove popup from active popups
        for (webViewId, popupState) in activeBlockingPopups {
            if popupState.sessionId == sessionId {
                activeBlockingPopups.removeValue(forKey: webViewId)
                logger.info("🙈 Hiding blocking popup for session: \(sessionId)")
                break
            }
        }
    }

    /// Reload a WebView with content blocking temporarily disabled
    /// - Parameters:
    ///   - webView: The WebView to reload
    ///   - url: The URL to load
    private func reloadWithoutBlocking(webView: WKWebView, url: URL) {
        logger.info("🔄 Reloading without blocking: \(url)")

        // Temporarily disable content blocking for this specific reload
        Task {
            // Remove content rules temporarily
            await webView.configuration.userContentController.removeAllContentRuleLists()

            // Load the URL
            webView.load(URLRequest(url: url))

            // Re-enable content blocking after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Task {
                    await ABManager.shared.applyContentBlocking(to: webView)
                }
            }
        }
    }

    /// Load the home page or a default page
    /// - Parameter webView: The WebView to load the home page in
    private func loadHomePage(webView: WKWebView) {
        // Load a default home page or blank page
        if let homeURL = URL(string: "about:blank") {
            webView.load(URLRequest(url: homeURL))
        }
    }

    /// Get a unique identifier for a WebView
    /// - Parameter webView: The WebView to get ID for
    /// - Returns: UUID if WebView can be identified, nil otherwise
    private func getWebViewId(_ webView: WKWebView) -> UUID? {
        // Try to get the WebView ID from the AltoWebView
        if let altoWebView = webView as? ADKWebView,
           let ownerTab = altoWebView.ownerTab {
            logger.debug("🔍 Found WebView ID from owner tab: \(ownerTab.id)")
            return ownerTab.id
        }

        // Fallback: use consistent object identifier
        let objectId = ObjectIdentifier(webView)
        let uuidString = String(
            format: "%016llx-%04x-%04x-%04x-%012llx",
            UInt64(objectId.hashValue),
            UInt16(0x4000),
            UInt16(0x8000),
            UInt16(0x0000),
            UInt64(0)
        )

        if let uuid = UUID(uuidString: uuidString) {
            logger.debug("🔍 Generated consistent WebView UUID: \(uuid)")
            return uuid
        }

        // Last resort: Create a new UUID and store it
        let newUUID = UUID()
        logger.warning("⚠️ Using new UUID for WebView: \(newUUID)")
        return newUUID
    }
}

// MARK: - BlockedSession

/// Represents a blocked content session
struct BlockedSession {
    let id: UUID
    let webView: WKWebView
    let blockedURL: URL
    let timestamp: Date
}

// MARK: - BlockingPopupState

/// State for the blocking popup UI
public struct BlockingPopupState: Identifiable {
    public let id = UUID()
    let sessionId: UUID
    let blockedURL: String
    let blockerInfo: String
    var isVisible: Bool

    /// Create closure functions for the popup actions
    func getContinueOnceAction() -> () -> () {
        {
            Task { @MainActor in
                ABBlockingManager.shared.continueOnce(sessionId: sessionId)
            }
        }
    }

    func getWhitelistAction() -> () -> () {
        {
            Task { @MainActor in
                ABBlockingManager.shared.whitelistPermanently(sessionId: sessionId)
            }
        }
    }

    func getCancelAction() -> () -> () {
        {
            Task { @MainActor in
                ABBlockingManager.shared.cancelBlocking(sessionId: sessionId)
            }
        }
    }
}
