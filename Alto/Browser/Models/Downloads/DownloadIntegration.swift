//
//  DownloadIntegration.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation
import OpenADK
import OSLog
import WebKit

// MARK: - DownloadIntegration

/// Handles integration of downloads with Alto's WebView system
@MainActor
public class DownloadIntegration: NSObject {
    public static let shared = DownloadIntegration()

    private let logger = Logger(subsystem: "com.alto.downloads", category: "DownloadIntegration")
    private let downloadManager = DownloadManager.shared
    private var setupWebViews: Set<ObjectIdentifier> = []

    // MARK: - Static Content Type & Extension Sets

    /// Content types that should NOT be downloaded (typically viewable in browser)
    private static let nonDownloadableContentTypes: Set<String> = [
        "text/html", "text/plain", "text/css", "text/javascript",
        "application/javascript", "application/x-javascript",
        "application/json", "application/xml", "text/xml"
    ]

    /// Extensions that should NOT be downloaded (typically viewable in browser)
    private static let nonDownloadableExtensions: Set<String> = [
        "html", "htm", "php", "asp", "aspx", "jsp", "js", "css",
        "json", "xml"
    ]

    /// File size threshold for automatic downloads (10MB)
    private static let autoDownloadSizeThreshold: Int64 = 10 * 1024 * 1024

    private override init() {
        super.init()
        setupDownloadNotificationListener()
    }

    // MARK: - Public Methods

    /// Setup download handling for a WebView
    public func setupDownloadHandling(for webView: WKWebView) {
        let webViewId = ObjectIdentifier(webView)

        // Check if already setup to prevent duplicate handlers
        guard !setupWebViews.contains(webViewId) else {
            logger.info("🔗 Download handling already setup for this WebView")
            return
        }

        // Enable download-related preferences
        webView.configuration.preferences.setValue(true, forKey: "allowsPictureInPictureMediaPlayback")
        webView.configuration.preferences.setValue(true, forKey: "javaScriptCanOpenWindowsAutomatically")

        // Add message handler for download requests (only if not already added)
        let userContentController = webView.configuration.userContentController

        // Remove existing handler if it exists (safety measure)
        userContentController.removeScriptMessageHandler(forName: "downloadHandler")

        // Add new handler
        userContentController.add(self, name: "downloadHandler")

        // Inject JavaScript for right-click download handling
        injectDownloadScript(into: webView)

        // Mark as setup
        setupWebViews.insert(webViewId)

        logger.info("🔗 Setting up download handling for WebView")
    }

    // MARK: - Private Methods

    /// Inject JavaScript for handling right-click downloads
    private func injectDownloadScript(into webView: WKWebView) {
        let downloadScript = """
        (function() {
            // Prevent duplicate injection
            if (window.altoDownloadSetup) return;
            window.altoDownloadSetup = true;

            // Store original context menu handler
            let originalContextMenu = null;

            // Override context menu to add download option
            document.addEventListener('contextmenu', function(event) {
                const target = event.target;

                // Check if target is an image, video, audio, or link
                if (target.tagName === 'IMG' || 
                    target.tagName === 'VIDEO' || 
                    target.tagName === 'AUDIO' || 
                    target.tagName === 'A' ||
                    target.tagName === 'OBJECT' ||
                    target.tagName === 'EMBED') {

                    let downloadUrl = null;
                    let filename = null;

                    if (target.tagName === 'IMG') {
                        downloadUrl = target.src || target.currentSrc;
                        filename = target.alt || 'image';
                    } else if (target.tagName === 'VIDEO') {
                        downloadUrl = target.src || target.currentSrc;
                        filename = target.title || 'video';
                    } else if (target.tagName === 'AUDIO') {
                        downloadUrl = target.src || target.currentSrc;
                        filename = target.title || 'audio';
                    } else if (target.tagName === 'A') {
                        downloadUrl = target.href;
                        filename = target.textContent || target.title || 'download';
                    } else if (target.tagName === 'OBJECT') {
                        downloadUrl = target.data;
                        filename = target.title || 'object';
                    } else if (target.tagName === 'EMBED') {
                        downloadUrl = target.src;
                        filename = target.title || 'embed';
                    }

                    if (downloadUrl) {
                        // Store download info for context menu
                        window.altoDownloadInfo = {
                            url: downloadUrl,
                            filename: filename,
                            element: target
                        };
                    }
                }
            }, true);

            // Function to trigger download
            window.altoTriggerDownload = function() {
                if (window.altoDownloadInfo) {
                    const info = window.altoDownloadInfo;

                    // Clean up filename
                    let cleanFilename = info.filename.replace(/[^a-zA-Z0-9._-]/g, '_');

                    // Try to get better filename from URL
                    try {
                        const url = new URL(info.url);
                        const urlFilename = url.pathname.split('/').pop();
                        if (urlFilename && urlFilename.includes('.')) {
                            cleanFilename = urlFilename;
                        }
                    } catch (e) {
                        // Use existing filename
                    }

                    // Send download request to native code
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.downloadHandler) {
                        window.webkit.messageHandlers.downloadHandler.postMessage({
                            action: 'download',
                            url: info.url,
                            filename: cleanFilename
                        });
                    }

                    // Clear download info
                    window.altoDownloadInfo = null;
                }
            };

            // Function to download current page
            window.altoDownloadPage = function() {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.downloadHandler) {
                    window.webkit.messageHandlers.downloadHandler.postMessage({
                        action: 'downloadPage',
                        url: window.location.href,
                        filename: document.title || 'page'
                    });
                }
            };

            // Auto-detect and handle downloads on page load
            document.addEventListener('DOMContentLoaded', function() {
                // Check if current page should be downloaded automatically
                const contentType = document.contentType || '';
                const url = window.location.href;

                // Auto-download if it's a direct file link
                if (contentType && !contentType.includes('text/html')) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.downloadHandler) {
                        window.webkit.messageHandlers.downloadHandler.postMessage({
                            action: 'autoDownload',
                            url: url,
                            contentType: contentType,
                            filename: url.split('/').pop() || 'download'
                        });
                    }
                }
            });

        })();
        """

        let userScript = WKUserScript(source: downloadScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(userScript)
    }

    /// Setup download notification listener
    private func setupDownloadNotificationListener() {
        // Listen for WebView creation
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AltoWebViewCreated"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let webView = notification.object as? WKWebView else {
                self?.logger.warning("⚠️ Download: Invalid WebView object in notification")
                return
            }

            self?.logger.info("🔌 Download: Setting up download handling for new WebView")
            self?.setupDownloadHandling(for: webView)
        }

        // Listen for download requests from WebViews
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AltoDownloadRequested"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo else { return }

            if let urlString = userInfo["url"] as? String,
               let url = URL(string: urlString) {
                let filename = userInfo["filename"] as? String
                self?.logger.info("🚀 Download: Received download request for \(filename ?? "unknown")")
                self?.downloadManager.startDownload(from: url, filename: filename)
            }
        }

        logger.info("👂 Download: Notification listeners registered")
    }

    /// Check if content should be downloaded based on multiple factors
    public static func shouldTriggerDownload(for response: HTTPURLResponse) -> Bool {
        // 1. Check Content-Disposition header (most reliable indicator)
        if let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String {
            let disposition = contentDisposition.lowercased()
            if disposition.contains("attachment") || disposition.contains("filename") {
                return true
            }
        }

        // 2. Check Content-Length for large files (auto-download large files)
        if let contentLengthString = response.allHeaderFields["Content-Length"] as? String,
           let contentLength = Int64(contentLengthString),
           contentLength > autoDownloadSizeThreshold {
            return true
        }

        // 3. Check if Content-Type suggests it's NOT a web page/viewable content
        if let contentType = response.allHeaderFields["Content-Type"] as? String {
            let cleanContentType = contentType.lowercased().components(separatedBy: ";").first?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            // If it's explicitly a non-viewable type, download it
            if !nonDownloadableContentTypes.contains(cleanContentType), !cleanContentType.isEmpty {
                // Additional check: if it's a generic type, it's likely downloadable
                if cleanContentType == "application/octet-stream" ||
                    cleanContentType.hasPrefix("application/") ||
                    cleanContentType.hasPrefix("audio/") ||
                    cleanContentType.hasPrefix("video/") ||
                    cleanContentType.hasPrefix("font/") {
                    return true
                }
            }
        }

        // 4. Check file extension as fallback
        if let url = response.url {
            let pathExtension = url.pathExtension.lowercased()

            // If it has an extension and it's not a typical web file, download it
            if !pathExtension.isEmpty, !nonDownloadableExtensions.contains(pathExtension) {
                return true
            }

            // Special case: files without extensions or with unusual names are likely downloads
            if pathExtension.isEmpty, !url.lastPathComponent.isEmpty {
                let lastComponent = url.lastPathComponent.lowercased()
                // If the filename looks like a download (has version numbers, etc.)
                if lastComponent.contains(where: \.isNumber) ||
                    lastComponent.contains("-") ||
                    lastComponent.contains("_") {
                    return true
                }
            }
        }

        // 5. Check HTTP status code - redirects to downloads often have specific patterns
        if response.statusCode == 200 {
            // Check if URL path suggests a download
            if let url = response.url {
                let path = url.path.lowercased()
                if path.contains("download") ||
                    path.contains("file") ||
                    path.contains("attachment") ||
                    path.contains("release") ||
                    path.contains("dist") {
                    return true
                }
            }
        }

        return false
    }

    /// Check if navigation action should trigger download based on URL patterns
    public static func shouldTriggerDownloadForNavigation(_ url: URL) -> Bool {
        let pathExtension = url.pathExtension.lowercased()
        let path = url.path.lowercased()
        let lastComponent = url.lastPathComponent.lowercased()

        // 1. File has a non-web extension
        if !pathExtension.isEmpty && !nonDownloadableExtensions.contains(pathExtension) {
            return true
        }

        // 2. URL path suggests download
        if path.contains("download") ||
            path.contains("file") ||
            path.contains("attachment") ||
            path.contains("release") ||
            path.contains("dist") ||
            path.contains("assets") {
            return true
        }

        // 3. Filename suggests it's a downloadable file
        if lastComponent.contains(where: \.isNumber),
           lastComponent.contains("-") || lastComponent.contains("_") || lastComponent.contains(".") {
            return true
        }

        // 4. Query parameters suggest download
        if let query = url.query?.lowercased() {
            if query.contains("download") ||
                query.contains("attachment") ||
                query.contains("file") {
                return true
            }
        }

        return false
    }

    /// Extract filename from response headers
    public static func extractFilename(from response: HTTPURLResponse) -> String? {
        guard let contentDisposition = response.allHeaderFields["Content-Disposition"] as? String else {
            return nil
        }

        // Parse filename from Content-Disposition header
        let components = contentDisposition.components(separatedBy: ";")
        for component in components {
            let trimmed = component.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("filename*=") {
                // Handle RFC 5987 encoded filenames
                let encodedFilename = trimmed.replacingOccurrences(of: "filename*=", with: "")
                if let decodedFilename = decodeRFC5987Filename(encodedFilename) {
                    return decodedFilename
                }
            } else if trimmed.hasPrefix("filename=") {
                let filename = trimmed.replacingOccurrences(of: "filename=", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                return filename
            }
        }

        return nil
    }

    /// Decode RFC 5987 encoded filename
    private static func decodeRFC5987Filename(_ encoded: String) -> String? {
        // Simple implementation for UTF-8 encoded filenames
        let parts = encoded.components(separatedBy: "'")
        if parts.count >= 3 {
            let encodedPart = parts[2]
            return encodedPart.removingPercentEncoding
        }
        return encoded.removingPercentEncoding
    }

    /// Generate smart filename from URL when no filename is provided
    private static func generateSmartFilename(from url: URL) -> String {
        var filename = url.lastPathComponent

        // Remove query parameters from filename first
        if let queryIndex = filename.firstIndex(of: "?") {
            filename = String(filename[..<queryIndex])
        }

        // If filename is empty or too generic, create a better one
        if filename.isEmpty || filename == "/" || filename.count < 3 {
            // Use domain and path to create filename
            let host = url.host ?? "download"
            let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }

            if !pathComponents.isEmpty {
                filename = "\(host)_\(pathComponents.joined(separator: "_"))"
            } else {
                filename = "\(host)_download"
            }
        }

        // Add extension if missing and we can infer it from URL
        if url.pathExtension.isEmpty {
            // Try to infer from URL content
            let urlString = url.absoluteString.lowercased()
            if urlString.contains(".zip") {
                filename += ".zip"
            } else if urlString.contains(".pdf") {
                filename += ".pdf"
            } else if urlString.contains(".mp4") {
                filename += ".mp4"
            } else if urlString.contains(".mp3") {
                filename += ".mp3"
            } else if urlString.contains(".png") {
                filename += ".png"
            } else if urlString.contains(".jpg") || urlString.contains(".jpeg") {
                filename += ".jpg"
            } else if urlString.contains(".gif") {
                filename += ".gif"
            } else if urlString.contains(".webp") {
                filename += ".webp"
            } else {
                // Default to appropriate extension based on URL patterns
                if urlString.contains("image") {
                    filename += ".png"
                } else if urlString.contains("video") {
                    filename += ".mp4"
                } else if urlString.contains("audio") {
                    filename += ".mp3"
                } else {
                    filename += ".download"
                }
            }
        }

        // Clean up filename - remove invalid characters
        filename = filename.replacingOccurrences(of: "[^a-zA-Z0-9._-]", with: "_", options: .regularExpression)

        return filename
    }

    /// Handle download initiation with unified logic
    public static func initiateDownload(from url: URL, suggestedFilename: String?) {
        let filename = suggestedFilename ?? generateSmartFilename(from: url)
        DispatchQueue.main.async {
            DownloadManager.shared.startDownload(from: url, filename: filename)
        }
    }
}

// MARK: WKScriptMessageHandler

extension DownloadIntegration: WKScriptMessageHandler {
    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "downloadHandler",
              let messageBody = message.body as? [String: Any] else {
            return
        }

        guard let action = messageBody["action"] as? String else {
            logger.warning("⚠️ Download: No action specified in message")
            return
        }

        switch action {
        case "download",
             "autoDownload":
            guard let urlString = messageBody["url"] as? String,
                  let url = URL(string: urlString) else {
                logger.warning("⚠️ Download: Invalid URL in download message")
                return
            }

            let filename = messageBody["filename"] as? String
            let cleanFilename = filename.map { _ in Self.generateSmartFilename(from: url) }
            logger.info("🚀 Download: JavaScript triggered download for \(cleanFilename ?? "unknown")")
            downloadManager.startDownload(from: url, filename: cleanFilename)

        case "downloadPage":
            guard let urlString = messageBody["url"] as? String,
                  let url = URL(string: urlString) else {
                logger.warning("⚠️ Download: Invalid URL in page download message")
                return
            }

            let filename = (messageBody["filename"] as? String ?? "page") + ".html"
            logger.info("🚀 Download: Page download requested for \(filename)")
            downloadManager.startDownload(from: url, filename: filename)

        default:
            logger.warning("⚠️ Download: Unknown action: \(action)")
        }
    }
}

// MARK: - WebPage Download Extension

public extension WebPage {
    /// Handle download responses in the navigation delegate
    @MainActor func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> ()
    ) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
              let url = response.url else {
            decisionHandler(.allow)
            return
        }

        // Check if this should trigger a download
        if DownloadIntegration.shouldTriggerDownload(for: response) {
            // Start download through our download manager
            let filename = DownloadIntegration.extractFilename(from: response)
            DownloadIntegration.initiateDownload(from: url, suggestedFilename: filename)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    /// Handle navigation actions that might be downloads
    @MainActor func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> ()
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Check if this looks like a download based on URL patterns
        if DownloadIntegration.shouldTriggerDownloadForNavigation(url) {
            DownloadIntegration.initiateDownload(from: url, suggestedFilename: nil)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }
}
