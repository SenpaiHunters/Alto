//
import Observation


/// AltoState handles the state for each window specificaly
/// 
/// Allows each window to display a diferent view of the tabs
@Observable
class AltoState {
    var data: Alto
    var sidebar = false
    var browserTabsManager: BrowserTabsManager?

    init() {
        data = Alto.shared

        self.browserTabsManager = BrowserTabsManager(state: self)
    }
    
    func setup(webView: WKWebView) {
        data.cookieManager.setupCookies(for: webView)
    }
}
