
import SwiftUI

@main
struct AltoApp: App {
    var browser: Browser = Browser()
    
    var body: some Scene {
        WindowGroup(id: "browser") {
            /// This is so we can manage the starting window with the browser class
            WindowView(window: browser.getWindow())
        }
        .environment(\.browser, browser)
    }
}
