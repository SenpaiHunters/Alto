import SwiftUI
import Observation

@Observable
class AltoData {
    static let shared = AltoData()
    let windowManager: WindowManager
    let cookieManager: CookiesManager
    
    private init() {
        windowManager = WindowManager()
        cookieManager = CookiesManager()
        
        WKWebsiteDataStore.nonPersistent()._setResourceLoadStatisticsEnabled(false)
        WKWebsiteDataStore.default()._setResourceLoadStatisticsEnabled(false)
    }
}

@Observable
class AltoState {
    var data: AltoData
    var sidebar = false
    var browserTabsManager: BrowserTabsManager?

    init() {
        data = AltoData.shared

        self.browserTabsManager = BrowserTabsManager(state: self)
    }
    
    func setup(webView: WKWebView) {
        data.cookieManager.setupCookies(for: webView)
    }
}

@Observable
class BrowserTabsManager {
    var state: AltoState
    var tabs: [AltoTab] = []
    var currentTab: AltoTab? {
        didSet {
            print(currentTab?.webView.url)
        }
    }
    
    init(state: AltoState) {
        self.state = state
        createNewTab()
    }
    
    func createNewTab(url: String = "https://www.google.com", frame: CGRect = .zero, configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
        let newWebView = AltoWebView(frame: frame, configuration: configuration)
        AltoData.shared.cookieManager.setupCookies(for: newWebView)
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            newWebView.load(request)
        }
        
        let newTab = AltoTab(webView: newWebView, state: state)
        tabs.append(newTab)
        currentTab = newTab
        print(tabs)
    }
}



@Observable
class AltoTab {
    let id = UUID()
    var webView: AltoWebView
    var state: AltoState
    let uiDelegateController = AltoWebViewDelegate()

    init(webView: AltoWebView, state: AltoState) {
        self.webView = webView
        self.state = state
        state.setup(webView: self.webView)
        webView.uiDelegate = uiDelegateController
        uiDelegateController.tab = self
    }
    
    func createNewTab(_ url: String, _ configuration: WKWebViewConfiguration, frame: CGRect = .zero) {
        let newWebView = AltoWebView(frame: frame, configuration: AltoWebViewConfigurationBase())
        

        AltoData.shared.cookieManager.setupCookies(for: newWebView)
        
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            newWebView.load(request)
        }
        print("called")
        let newTab = AltoTab(webView: newWebView, state: state)
        state.browserTabsManager?.tabs.append(newTab)
        state.browserTabsManager?.currentTab = newTab
    }
}

@Observable
class AltoWebViewDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    weak var tab: AltoTab?
    
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            print("🆕 New tab or window requested: \(navigationAction.request.url?.absoluteString ?? "unknown URL")")
            
            let newWebView = AltoWebView(frame: .zero, configuration: configuration)
            
            if let url = navigationAction.request.url?.absoluteString {
                let newTab = AltoTab(webView: newWebView, state: tab?.state ?? AltoState())
                
                tab?.state.browserTabsManager?.tabs.append(newTab)
                tab?.state.browserTabsManager?.currentTab = newTab
                AltoData.shared.cookieManager.setupCookies(for: newWebView)
                newWebView.uiDelegate = AltoWebViewDelegate()
                
                newWebView.load(URLRequest(url: URL(string: url)!))
            }
            return newWebView
        }
        return nil
    }
}

@Observable
// Roles the WebView and WebViewManager into one
class AltoWebView: WKWebView {
    #if DEVELOPMENT
    static var aliveWebViewsCount: Int = 0
    #endif
    var currentConfiguration: WKWebViewConfiguration
    var delegate: WKUIDelegate?
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        currentConfiguration = configuration
        
        super.init(frame: frame, configuration: configuration)
        #if DEVELOPMENT
        AltoWebView.aliveWebViewsCount += 1
        #endif
        allowsMagnification = true
        customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    deinit {
        #if DEVELOPMENT
        AltoWebView.aliveWebViewsCount -= 1
        #endif
    }
    
    
}

extension WKWebView {
    /// WKWebView's `configuration` is marked with @NSCopying.
    /// So everytime you try to access it, it creates a copy of it, which is most likely not what we want.
    var configurationWithoutMakingCopy: WKWebViewConfiguration {
        (self as? AltoWebView)?.currentConfiguration ?? configuration
    }
    
}


