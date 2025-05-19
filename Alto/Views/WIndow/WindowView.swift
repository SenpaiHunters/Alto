
import SwiftUI
import Observation

/// This handles any window specific information like the specific space that is open, windows size and position
@Observable
class Window: Identifiable {
    var id = UUID()
    var title: String
    var manager: Browser  // uses the browser environment for managment
    var state: States = .topbar
    var activeTab: TabRepresentation? = nil
    var nsWindow: NSWindow?
    
    enum States {
        case sidebar, topbar
    }
    
    init(manager: Browser) {
        self.manager = manager
        self.title = ""
    }
}

struct WindowView: View {
    @Environment(\.appearsActive) private var appearsActive
    @Environment(\.browser) private var browser
    var window: Window /// takes window class for handling the view
    
    var body: some View {
        BrowserView(BrowserViewModel(browser: browser, window: window))
            .onChange(of: appearsActive) {
                if appearsActive {
                    browser.activeWindow = window.id
                }
            }
    }
}
