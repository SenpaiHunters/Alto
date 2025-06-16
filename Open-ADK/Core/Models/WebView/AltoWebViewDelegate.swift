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
        print("OPEN WINDOW")
        if navigationAction.targetFrame == nil {
            print("New tab or window requested: \(navigationAction.request.url?.absoluteString ?? "unknown URL")")
            
            let newWebView = AltoWebView(frame: .zero, configuration: configuration)
            
            print("URL:", navigationAction.request.url)
            if navigationAction.request.url == nil {
                return nil
            }
            if navigationAction.navigationType == .other {
                print("THe browser has requested a login expereicnce")
            }
            if navigationAction.request.url?.absoluteString == "" {
                return nil
            }
            if let url = navigationAction.request.url?.absoluteString {
                let newTab = AltoTab(webView: newWebView, state: tab?.state ?? AltoState())
                let tabRep = TabRepresentation(id:newTab.id, index: tab?.mannager?.currentSpace.normal.tabs.count ?? 0)
                Alto.shared.tabs[newTab.id] = newTab
                
                tab?.mannager?.currentSpace.normal.appendTabRep(tabRep)
                tab?.mannager?.currentSpace.currentTab = newTab
                Alto.shared.cookieManager.setupCookies(for: newWebView)
                
                // newWebView.load(navigationAction.request)
            }
            return newWebView
        }
        return nil
    }
    
    func webViewDidClose(_ webView: WKWebView) {
            print("CLOSE")
        }
}

class AltoWebViewNavagationDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
        
        }
    }
}
