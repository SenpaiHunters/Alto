//
import Observation


/// AltoState handles the state for each window specificaly
/// 
/// Allows each window to display a diferent view of the tabs
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
