import SwiftUI
import Observation


/// Manges Tabs for each Window
///
///  Tabs will be stored in AltoData in future in order to support tabs being shared between windows (like Arc)
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


/// Simple tab implimentation
///
/// This will be changed to a base class later to support Tab Folders, SplitView, ect.
@Observable
class AltoTab: Identifiable {
    let id = UUID()
    var webView: AltoWebView
    var state: AltoState
    let uiDelegateController = AltoWebViewDelegate()
    let navigationDelegateControllor = AltoWebViewNavagationDelegate()

    init(webView: AltoWebView, state: AltoState) {
        self.webView = webView
        self.state = state
        state.setup(webView: self.webView)
        webView.uiDelegate = uiDelegateController
        webView.navigationDelegate = navigationDelegateControllor
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
