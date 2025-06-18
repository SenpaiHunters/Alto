import SwiftUI

// MARK: - AltoTab

/// Simple tab implementation
///
/// This will be changed to a base class later to support Tab Folders, SplitView, ect.
@Observable
class AltoTab: NSObject, Identifiable {
    let id = UUID()
    var location: TabLocation?
    var webView: AltoWebView
    var state: AltoState
    let uiDelegateController = AltoWebViewDelegate()
    let mannager: BrowserTabsManager?

    var title = "Untitled"
    var favicon: Image?
    var canGoBack = false
    var canGoForward = false

    var isLoading = false
    var url: URL? = nil

    init(webView: AltoWebView, state: AltoState) {
        self.webView = webView
        self.state = state
        mannager = state.browserTabsManager
        super.init()

        state.setup(webView: self.webView)
        webView.uiDelegate = uiDelegateController
        webView.navigationDelegate = self
        uiDelegateController.tab = self
    }

    deinit {
        print("deinit")
        webView.uiDelegate = nil
        webView.navigationDelegate = nil
        webView.stopLoading()
    }

    func createNewTab(_ url: String, _ configuration: WKWebViewConfiguration, frame: CGRect = .zero) {
        let newWebView = AltoWebView(frame: frame, configuration: AltoWebViewConfigurationBase())

        Alto.shared.cookieManager.setupCookies(for: newWebView)

        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            newWebView.load(request)
        }
        print("called")
        let newTab = AltoTab(webView: newWebView, state: state)
        let tabRep = TabRepresentation(id: newTab.id, index: mannager?.currentSpace.normal.tabs.count ?? 0)
        mannager?.currentSpace.normal.appendTabRep(tabRep)
        Alto.shared.tabs[newTab.id] = newTab
        mannager?.currentSpace.currentTab = newTab
    }

    func closeTab() {
        Alto.shared.removeTab(id)
        location?.removeTab(id: id)
        mannager?.currentSpace.currentTab = nil
    }
}

// MARK: WKNavigationDelegate, WKUIDelegate

extension AltoTab: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("FINISHED LOADING")
        if webView.title == "" {
            title = webView.url?.absoluteString ?? "Untitled"
        } else {
            title = webView.title ?? "Untitled"
        }
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward

        getFavicon()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("start")
            // Alto.shared.contextManager.pullContextFromPage(for: webView)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("STARTED LOADING")
        isLoading = false
        url = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }

    func webViewDidClose(_ webView: WKWebView) {
        print("YES")
    }

    func webView(_ webView: WKWebView, willPerformNavigationAction action: WKNavigationAction) {
        print("REDIRECTED?????????????????")
    }

    func getFavicon() {
        webView.evaluateJavaScript(
            "document.querySelector(\"link[rel~='icon']\")?.href"
        ) { result, _ in
            if let value = result as? String {
                print("VALUE: ", value)
                print("Favicon URL from JS:", value)
                self.fetchFaviconUsingManager(from: value)
            } else {
                if let host = self.webView.url?.host {
                    let fallbackFavicon = "https://\(host)/favicon.ico"
                    print("Using fallback favicon:", fallbackFavicon)
                    self.fetchFaviconUsingManager(from: fallbackFavicon)
                }
            }
        }
    }

    private func fetchFaviconUsingManager(from urlString: String) {
        FaviconManager.shared.fetchFavicon(for: urlString) { [weak self] nsImage in
            guard let self, let nsImage else { return }

            DispatchQueue.main.async {
                self.favicon = Image(nsImage: nsImage)
            }
        }
    }
}
