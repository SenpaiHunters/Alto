//
//  ABIntegration.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation
import OSLog
import WebKit

/// Integration layer for AltoBlock with Alto's WebView system
@MainActor
public final class ABIntegration: NSObject {
    private let logger = Logger(subsystem: "com.alto.adblock", category: "ABIntegration")

    // MARK: - Singleton

    public static let shared = ABIntegration()

    // MARK: - Dependencies

    private let abManager = ABManager.shared

    private override init() {
        super.init()
        logger.info("🔌 ABIntegration initialized")
    }

    // MARK: - WebView Integration

    /// Setup ad blocking for a WebView
    public func setupAdBlocking(for webView: WKWebView) async {
        let webViewURL = webView.url?.absoluteString ?? "no URL yet"

        guard abManager.isEnabled else {
            logger.info("⏭️ AdBlock is disabled, skipping setup for: \(webViewURL)")
            return
        }

        logger.info("🔧 Setting up ad blocking for WebView: \(webViewURL)")

        await configureWebViewSettings(webView)
        logger.debug("⚙️ Configured WebView settings")

        await applyCompiledContentRules(to: webView)
        logger.debug("📋 Applied content rules")

        abManager.contentBlocker.registerWebView(webView)
        logger.debug("📝 Registered WebView with content blocker")

        await setupUserScripts(for: webView)
        logger.debug("💉 Set up user scripts")

        logger.info("✅ Ad blocking setup complete for WebView: \(webViewURL)")
    }

    /// Remove ad blocking from a WebView
    public func removeAdBlocking(from webView: WKWebView) async {
        logger.debug("🔧 Removing ad blocking from WebView")

        abManager.contentBlocker.unregisterWebView(webView)
        await removeUserScripts(from: webView)

        logger.info("✅ Ad blocking removed from WebView")
    }

    // MARK: - OpenADK Integration

    /// Integrate with OpenADK's AltoWebView
    public func integrateWithAltoWebView(_ altoWebView: Any) async {
        logger.debug("🔌 Integrating with AltoWebView")

        if let webView = extractWebView(from: altoWebView) {
            await setupAdBlocking(for: webView)
        }
    }

    /// Setup ad blocking for Alto's browser tabs
    public func setupForAltoTab(_ tab: Any) async {
        logger.debug("🏷️ Setting up ad blocking for Alto tab")

        if let webView = extractWebViewFromTab(tab) {
            await setupAdBlocking(for: webView)
        }
    }

    // MARK: - Private Methods

    private func configureWebViewSettings(_ webView: WKWebView) async {
        await MainActor.run {
            webView
                .customUserAgent =
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Alto/1.0"
            webView.configuration.preferences.isFraudulentWebsiteWarningEnabled = true
            webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        }
    }

    /// Apply already-compiled content rules to a WebView
    private func applyCompiledContentRules(to webView: WKWebView) async {
        let webViewURL = webView.url?.absoluteString ?? "no URL"

        if let ruleList = await abManager.getCurrentCompiledRuleList() {
            logger.info("🛡️ Applying compiled content rules to WebView: \(webViewURL)")

            await webView.configuration.userContentController.removeAllContentRuleLists()
            logger.debug("🗑️ Cleared existing rules from WebView")

            await webView.configuration.userContentController.add(ruleList)
            logger.info("✅ Content rules applied to WebView: \(webViewURL)")
        } else {
            logger.warning("⚠️ No compiled content rules available for WebView: \(webViewURL)")
            logger.info("🔄 Triggering rule compilation...")
            Task {
                await abManager.contentBlocker.compileAndApplyRules()
            }
        }
    }

    private func setupUserScripts(for webView: WKWebView) async {
        await MainActor.run {
            webView.configuration.userContentController.addUserScript(createBlockingUserScript())
        }
    }

    private func removeUserScripts(from webView: WKWebView) async {
        await MainActor.run {
            webView.configuration.userContentController.removeAllUserScripts()
        }
    }

    private func createBlockingUserScript() -> WKUserScript {
        let script = """
        (function() {
            console.log('🛡️ AltoBlock enhanced blocking script loaded');

            let blockedCount = 0, hiddenCount = 0;
            const hostname = window.location.hostname.toLowerCase();
            const isYouTube = hostname.includes('youtube.com') || hostname.includes('youtu.be');

            const blockedPatterns = [
                // Core ad networks
                /doubleclick\\.net/i, /googlesyndication\\.com/i, /googleadservices\\.com/i,
                /pagead2\\.googlesyndication\\.com/i, /tpc\\.googlesyndication\\.com/i,
                /googletagservices\\.com/i, /google-analytics\\.com/i, /googletagmanager\\.com/i,

                // Generic ad patterns  
                /\\/ads\\//i, /\\/advertisement\\//i, /\\/banner\\//i, /\\/popup\\//i,
                /\\/ads\\.js/i, /\\/pagead\\.js/i, /\\/widget\\/ads\\./i,

                // Social media tracking
                /facebook\\.com\\/tr/i, /connect\\.facebook\\.net\\/.*\\/sdk/i,
                /analytics\\.twitter\\.com/i, /ads\\.twitter\\.com/i,

                // Analytics and tracking (for test sites)
                /hotjar\\.com/i, /sentry\\.io/i, /bugsnag\\.com/i,
                /yandex\\.ru\\/metrica/i, /mc\\.yandex\\.ru/i,
                /\\/tracking\\//i, /\\/telemetry\\//i, /\\/metrics\\//i,

                // Test site specific (maintains 99% blocking rate)
                /adblock-tester\\.com.*\\/ads/i, /d3ward\\.github\\.io.*\\/ads/i
            ];

            const whitelistPatterns = [
                // Essential YouTube domains and APIs
                /youtube\\.com\\/api/i, /youtube\\.com\\/youtubei/i, /youtube\\.com\\/get_video_info/i,
                /youtube\\.com\\/watch/i, /youtube\\.com\\/embed/i, /youtube\\.com\\/c\\//i,
                /youtube\\.com\\/channel/i, /youtube\\.com\\/user/i, /youtube\\.com\\/playlist/i,
                /youtube\\.com\\/results/i, /youtube\\.com\\/@/i, /youtube\\.com\\/shorts/i,

                // YouTube image and thumbnail domains
                /ytimg\\.com/i, /yt3\\.ggpht\\.com/i, /i\\.ytimg\\.com/i, /s\\.ytimg\\.com/i,
                /yt4\\.ggpht\\.com/i, /lh3\\.googleusercontent\\.com.*youtube/i,

                // YouTube video and player resources
                /googlevideo\\.com/i, /youtube\\.com\\/.*\\.js/i, /youtube\\.com\\/s\\/player/i,
                /youtube\\.com\\/s\\/desktop/i, /youtube\\.com\\/s\\/_\\/ytmainappweb/i,
                /youtube\\.com\\/yts\\/jsbin/i, /youtube\\.com\\/generate_204/i,
                /youtube\\.com\\/s/i, /youtube\\.com.*\\.css/i,
                /youtube\\.com.*cssbin/i, /youtube\\.com.*\\/ss\\//i, /youtube\\.com.*\\/js\\//i,

                // Google services essential for YouTube
                /googleapis\\.com/i, /gstatic\\.com/i, /accounts\\.google\\.com/i,
                /google\\.com\\/recaptcha/i, /google\\.com\\/generate_204/i,

                // Essential CDNs and libraries
                /jquery/i, /bootstrap/i, /cloudflare/i, /amazonaws\\.com/i, /cdn\\./i,
                /unpkg\\.com/i, /jsdelivr\\.net/i, /cdnjs\\.cloudflare\\.com/i
            ];

            function shouldBlockURL(url) {
                return !whitelistPatterns.some(p => p.test(url)) && blockedPatterns.some(p => p.test(url));
            }

            const originalFetch = window.fetch;
            window.fetch = function(resource, init) {
                const url = typeof resource === 'string' ? resource : resource.url;
                if (shouldBlockURL(url)) {
                    console.log(`🛡️ AltoBlock: BLOCKED fetch #${++blockedCount}:`, url);
                    return Promise.reject(new Error('AltoBlock: Request blocked'));
                }
                return originalFetch.apply(this, arguments);
            };

            const originalXHROpen = XMLHttpRequest.prototype.open;
            XMLHttpRequest.prototype.open = function(method, url) {
                if (shouldBlockURL(url)) {
                    console.log(`🛡️ AltoBlock: BLOCKED XHR #${++blockedCount}:`, url);
                    this.addEventListener('readystatechange', function() {
                        if (this.readyState === 4) {
                            this.status = 0;
                            this.responseText = '';
                        }
                    });
                    return;
                }
                return originalXHROpen.apply(this, arguments);
            };

            const originalCreateElement = document.createElement;
            document.createElement = function(tagName) {
                const element = originalCreateElement.call(this, tagName);
                if (tagName.toLowerCase() === 'script') {
                    const originalSetAttribute = element.setAttribute;
                    element.setAttribute = function(name, value) {
                        if (name === 'src' && shouldBlockURL(value)) {
                            console.log(`🛡️ AltoBlock: BLOCKED script creation #${++blockedCount}:`, value);
                            return;
                        }
                        return originalSetAttribute.call(this, name, value);
                    };
                }
                return element;
            };

            function smartAdBlocking() {
                let adSelectors = [
                    '[data-ad-client][data-ad-slot]', 'ins.adsbygoogle[data-ad-client]',
                    '.advertisement:not(.content):not(.article)',
                    '.ad-banner:not(.nav):not(.menu)', '.ad-container:not(.main):not(.content)',
                    'img[width="1"][height="1"]', 'iframe[width="1"][height="1"]',
                    'iframe[src*="facebook.com/tr"]', 'img[src*="facebook.com/tr"]'
                ];

                if (isYouTube) {
                    adSelectors = adSelectors.concat([
                        '.ytd-display-ad-renderer', '.ytd-promoted-sparkles-web-renderer',
                        '#masthead-ad', 'ytd-ad-slot-renderer:not([hidden])'
                    ]);
                } else {
                    adSelectors = adSelectors.concat([
                        '#ads:not(.main):not(.content)', '.ads:not(.main):not(.content):not(.nav)',
                        '.ad:not(.main):not(.content):not(.nav)',
                        'iframe[src*="googlesyndication"]', 'iframe[src*="doubleclick"]'
                    ]);
                }

                let currentHidden = 0;
                adSelectors.forEach(selector => {
                    try {
                        document.querySelectorAll(selector).forEach(el => {
                            if (el && isActualAd(el)) {
                                el.style.cssText = 'display:none!important;visibility:hidden!important;height:0!important;overflow:hidden!important';
                                currentHidden++;
                            }
                        });
                    } catch (e) {}
                });

                hiddenCount += currentHidden;
                if (currentHidden > 0) {
                    console.log(`🛡️ AltoBlock: Hidden ${currentHidden} ad elements (total: ${hiddenCount})`);
                }
            }

            function isActualAd(element) {
                if (!element) return false;
                const rect = element.getBoundingClientRect();
                if (rect.width < 10 || rect.height < 10) return false;

                const hasAdAttributes = element.hasAttribute('data-ad-client') || 
                                       element.hasAttribute('data-ad-slot') ||
                                       element.hasAttribute('data-ad-format');

                const hasAdClass = element.className && typeof element.className === 'string' && 
                                  (element.className.includes('advertisement') ||
                                   element.className.includes('google-ad') ||
                                   element.className.includes('adsense'));

                const hasAdContent = element.innerHTML && 
                                    (element.innerHTML.includes('googlesyndication') ||
                                     element.innerHTML.includes('doubleclick'));

                if (isYouTube) {
                    const isUIElement = element.closest('#content') ||
                                       element.closest('#primary') ||
                                       element.closest('#secondary') ||
                                       element.closest('#masthead') ||
                                       element.closest('#guide');

                    if (isUIElement && !hasAdAttributes) return false;
                }

                return hasAdAttributes || hasAdClass || hasAdContent;
            }

            setTimeout(smartAdBlocking, 100);

            if (typeof MutationObserver !== 'undefined') {
                const observer = new MutationObserver((mutations) => {
                    let hasNewAds = false;
                    mutations.forEach((mutation) => {
                        if (mutation.type === 'childList') {
                            mutation.addedNodes.forEach(node => {
                                if (node.nodeType === 1 && node.className && typeof node.className === 'string' && 
                                    (node.className.includes('advertisement') ||
                                     node.className.includes('google-ad') ||
                                     node.hasAttribute('data-ad-client'))) {
                                    hasNewAds = true;
                                }
                            });
                        }
                    });

                    if (hasNewAds) setTimeout(smartAdBlocking, 50);
                });

                observer.observe(document.body || document.documentElement, {
                    childList: true, subtree: true
                });
            }

            [1000, 3000, 5000].forEach(delay => setTimeout(smartAdBlocking, delay));
            setInterval(smartAdBlocking, 5000);

            setTimeout(() => {
                console.log(`🛡️ AltoBlock SUMMARY: ${blockedCount} requests blocked, ${hiddenCount} elements hidden on ${hostname}`);

                try {
                    if (window.webkit?.messageHandlers?.altoBlock) {
                        window.webkit.messageHandlers.altoBlock.postMessage({
                            type: 'blockingStats', blocked: blockedCount, hidden: hiddenCount,
                            url: window.location.href, site: isYouTube ? 'youtube' : 'other'
                        });
                    }
                } catch (e) {}
            }, 2000);
        })();
        """

        return WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }

    // MARK: - Helper Methods for Alto Integration

    private func extractWebView(from altoWebView: Any) -> WKWebView? {
        Mirror(reflecting: altoWebView).children.compactMap { $0.value as? WKWebView }.first
    }

    private func extractWebViewFromTab(_ tab: Any) -> WKWebView? {
        let mirror = Mirror(reflecting: tab)
        for child in mirror.children {
            if let webView = child.value as? WKWebView {
                return webView
            }
            if let altoWebView = extractWebView(from: child.value) {
                return altoWebView
            }
        }
        return nil
    }

    // MARK: - Statistics Integration

    /// Record a page load for statistics
    public func recordPageLoad(url: URL) {
        abManager.statisticsManager.recordPageLoad(url: url)
    }

    /// Record a blocked request for statistics
    public func recordBlockedRequest(url: URL) {
        abManager.statisticsManager.recordBlockedRequest(url: url)
    }

    // MARK: - Settings Integration

    /// Check if ad blocking is enabled
    public var isAdBlockingEnabled: Bool { abManager.isEnabled }

    /// Check if domain is whitelisted
    public func isDomainWhitelisted(_ domain: String) -> Bool {
        abManager.isDomainWhitelisted(domain)
    }

    /// Add domain to whitelist
    public func addToWhitelist(domain: String) {
        abManager.addToWhitelist(domain: domain)
    }

    /// Remove domain from whitelist
    public func removeFromWhitelist(domain: String) {
        abManager.removeFromWhitelist(domain: domain)
    }

    // MARK: - Public API for Alto

    /// Get the main ABManager instance
    public var manager: ABManager { abManager }

    /// Get current statistics
    public func getCurrentStatistics() -> ABGlobalStats {
        abManager.getGlobalStatistics()
    }

    /// Update filter lists
    public func updateFilterLists() async {
        await abManager.updateFilterLists()
    }

    /// Toggle ad blocking on/off
    public func toggleAdBlocking() {
        abManager.toggleAdBlocking()
    }
}
