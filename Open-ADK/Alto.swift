//
import Observation


/// Alto handles the data for the entire browser
/// 
/// Data here is shared between all windows
@Observable
class Alto {
    static let shared = Alto()
    let windowManager: WindowManager
    let cookieManager: CookiesManager
    let contextManager: ContextManager
    let llmManager: LLMManager
    #warning("Tab Data (but not managment) will be moved here. windows share tabs but display diferently (like Arc)")
    
    private init() {
        // These are state agnostic managers that will be used no matter what
        // Each window hanles its own tab managment but the singleton handles the browser as a whole
        windowManager = WindowManager()
        cookieManager = CookiesManager()
        contextManager = ContextManager()
        llmManager = LLMManager()

        
        // Uses Apple private APIs to allow 3rd party cookies to work
        WKWebsiteDataStore.nonPersistent()._setResourceLoadStatisticsEnabled(false)
        WKWebsiteDataStore.default()._setResourceLoadStatisticsEnabled(false)
    }
}


