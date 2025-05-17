import SwiftUI
import SwiftData
import Observation

/// Manages the Browser View
@Observable
class BrowserViewModel {
    var browser: Browser
    var window: Window
    
    init(browser: Browser, window: Window) {
        self.browser = browser
        self.window = window
    }
}


/// This is a temporary window view for testing
struct BrowserView: View {
    var model: BrowserViewModel
    
    /// Views should have an init so you dont have to enter model: for each view
    init(_ model: BrowserViewModel) {
        self.model = model
    }
    
    var body: some View {
        HStack(spacing: 0) {
            if model.window.state == .sidebar {
                SidebarView(window: model.window)
            }

            /// Places TopbarView in nested stack so web content doesnt need to be rerendered
            VStack(spacing: 0) {
                if model.window.state == .topbar {
                    TopbarView(window: model.window)
                }

                /// Gets webview from active tab
                ZStack {
                    if let id = model.browser.activeTab {
                        if let webManager = model.browser.tabFromId(id.id) {
                            WebView(webViewMannager: webManager)
                                .id(id)
                                .cornerRadius(5)
                        }
                        /// if there is no active tab it will display a default view
                    } else {
                        Rectangle()
                            .fill(.red)
                            .cornerRadius(5)
                    }
                }
                .padding(5)
            }
        }
    }
}

struct SidebarView: View {
    @Environment(\.browser) private var browser
    var window: Window
    
    var body: some View {
        VStack {
            /// The drop areas for the tabs
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.favoritesId))
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.getSpace().pinnedId))
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.getSpace().unpinnedId))
            Spacer()
            
            Button {
                browser.newTab()
            } label: {
                Text("New Tab")
            }
            Button {
                window.state = .topbar
            } label: {
                Text("toggle")
            }
        }
    }
}

struct TopbarView: View {
    @Environment(\.browser) private var browser
    var window: Window
    
    var body: some View {
        HStack {
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.favoritesId))
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.getSpace().pinnedId))
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.getSpace().unpinnedId))
            Spacer()
            
            Button {
                browser.newTab()
            } label: {
                Text("New Tab")
            }
            Button {
                window.state = .sidebar
            } label: {
                Text("toggle")
            }
        }
    }
}
