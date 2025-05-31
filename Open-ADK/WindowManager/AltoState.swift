//
import Observation



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
