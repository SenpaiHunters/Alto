//
import Observation


/// Alto handles the data for the entire browser
/// 
/// Data here is shared between all windows
@Observable
class Alto {
    static let shared = Alto()
    var tabs: [UUID:AltoTab] = [:]
    var spaces: [Space] = [Space(), Space()]
    let windowManager: WindowManager
    let cookieManager: CookiesManager
    let contextManager: NewContextManager
    
    private init() {
        // These are state agnostic managers that will be used no matter what
        // Each window hanles its own tab managment but the singleton handles the browser as a whole
        windowManager = WindowManager()
        cookieManager = CookiesManager()
        contextManager = NewContextManager()

        
        // Uses Apple private APIs to allow 3rd party cookies to work
         WKWebsiteDataStore.nonPersistent()._setResourceLoadStatisticsEnabled(false)
         WKWebsiteDataStore.default()._setResourceLoadStatisticsEnabled(false)
    }
    
    func getTab(id: UUID) -> AltoTab? {
        let tab = self.tabs.first(where: { $0.key == id})?.value
        return tab
    }
    
    func removeTab(_ id: UUID) {
        let tab = self.getTab(id: id)
        tab?.location?.removeTab(id:id)
        self.tabs.removeValue(forKey: id)
    }
}
