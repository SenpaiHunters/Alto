//
import Observation


/// Handles navigation requests from the Webview
/// 
/// This may be wraped into the tab for managment in future
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
                Alto.shared.cookieManager.setupCookies(for: newWebView)
                
                newWebView.load(URLRequest(url: URL(string: url)!))
            }
            return newWebView
        }
        return nil
    }
}

class AltoWebViewNavagationDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            Alto.shared.contextManager.pullContextFromPage(for: webView)
        }
    }
}
