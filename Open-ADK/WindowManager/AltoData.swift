//
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
