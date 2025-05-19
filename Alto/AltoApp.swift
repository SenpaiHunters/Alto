
import SwiftUI

@main
struct AltoApp: App {
    @Environment(\.appearsActive) private var appearsActive
    var browser: Browser = Browser()
    
    var body: some Scene {
        WindowGroup(id: "browser") {
            /// This is so we can manage the starting window with the browser class
            WindowView(window: browser.windows[0])
        }
        .environment(\.browser, browser)
    }
}
