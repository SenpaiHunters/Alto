import SwiftUI


/// Simple tab implimentation
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
    
    var title: String = "Untitled"
    var favicon: Image?
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    
    var isLoading: Bool = false
    var url: URL? = nil
    
    init(webView: AltoWebView, state: AltoState) {
        self.webView = webView
        self.state = state
        self.mannager = state.browserTabsManager
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
        Alto.shared.removeTab(self.id)
        self.location?.removeTab(id: self.id)
        self.mannager?.currentSpace.currentTab = nil
    }
}


extension AltoTab: WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("FINISHED LOADING")
        if webView.title == "" {
            self.title = webView.url?.absoluteString ?? "Untitled"
        } else {
            self.title = webView.title ?? "Untitled"
        }
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward

        getFavicon()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("start")
            // Alto.shared.contextManager.pullContextFromPage(for: webView)
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("STARTED LOADING")
        self.isLoading = false
        self.url = webView.url
        self.canGoBack = webView.canGoBack
        self.canGoForward = webView.canGoForward
    }
    
    func getFavicon() {
        webView.evaluateJavaScript(
            "document.querySelector(\"link[rel~='icon']\")?.href"
        ) { result, error in
            if let value = result as? String {
                print("VALUE: ", value)
                print("Favicon URL from JS:", value)
                self.downloadFavicon(from: value)
            } else {
                if let host = self.webView.url?.host {
                    let fallbackFavicon = "https://\(host)/favicon.ico"
                    print("Using fallback favicon:", fallbackFavicon)
                    self.downloadFavicon(from: fallbackFavicon)
                }
            }

        }
    }

    func downloadFavicon(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.favicon = Image(nsImage: image)
                }
            }
        }.resume()
    }
}

