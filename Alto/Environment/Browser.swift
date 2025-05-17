
import SwiftUI
import Observation
import AppKit

/// allows browser class to be accsesed in all views
extension EnvironmentValues {
    @Entry var browser: Browser = Browser()
}

/// This handles any data that needs to be shared across all windows and subviews
@Observable
class Browser: Identifiable {
    /// this will keep track of browser windows
    var windows: [Window] = []
    
    var id: UUID = UUID()
    /// holds all tab objects for reference via ID
    /// Tabs are shared between all windows
    /// If tabs are held inside other tabs it requires recursion to find and deleat them
    /// this way all you need is an ID an you can look up the tab
    public var tabs: [TabItem] = []
    
    /// TODO: This should be refactored into a struct of some sort
    var favoritesId = UUID()
    var favorites: [TabRepresentation] = []
    
    var spaceIndex: Int = 0
    var spaces: [Space] = []
    
    var activeTab: TabRepresentation? = nil
    
    init() {
        print("Browser Init")
        /// Use a function to pull from a stored json
        self.windows = []
        /// Use a function to pull from a stored json
        self.tabs = []
        
        self.spaces = [
            Space(manager: self),
            Space(manager: self)
        ]

        /// In the case there are no windows pulled from memory it will make a new one
        if self.windows.count < 1 {
            self.windows.append(Window(manager: self))
        }
        
        if getSpace().unpinned.count > 0 {
            self.activeTab = getSpace().unpinned[0]
        }
    }
    
    func newTab(_ url: String = "https://www.google.com/") {
        let newTab = Tab(self, url: URL(string: url))
        let newTabRepresentation = TabRepresentation(id: newTab.id, title: "Tab 0", favicon: "")
        self.tabs.append(newTab)
        self.getSpace().unpinned.append(newTabRepresentation)
        self.activeTab = newTabRepresentation
    }
    
    /// TODO: make this actualy work
    func getSpace() -> Space {
        return spaces[spaceIndex]
    }
    
    /// Gets a tab object from its ID
    func tabFromId(_ id: UUID) -> WebViewManager? {
        if let tab = tabs.first(where: { $0.id == id}) {
            if let tab = tab as? Tab {
                return tab.webviewManager
            }
        }
        return nil
    }
    
    /// This will eventualy remove the tab from each location
    func removeTab(tab: TabRepresentation) {
        self.getSpace().removeTab(tab: tab)
        self.favorites.removeAll(where: { $0 == tab })
    }
    
    /// gets tabs based on a dropzones Ids
    func getTabs(id: UUID) -> [TabRepresentation] {
        if id == self.getSpace().pinnedId {
            return self.getSpace().pinned
        } else if id == self.getSpace().unpinnedId {
            return self.getSpace().unpinned
        }
        return favorites
    }
    
    func getWindow(id: UUID? = nil) -> Window {
        if id == nil {
            return windows[0]
        } else {
            let returnedWindow = windows.first(where: { $0.id == id})
            return returnedWindow!
        }
    }
    
    func setTabArray(_ id: UUID, tabs: [TabRepresentation]) {
        if id == self.getSpace().pinnedId {
             self.getSpace().pinned  = tabs
        } else if id == self.getSpace().unpinnedId {
             self.getSpace().unpinned  = tabs
        } else {
            favorites = tabs
        }
    }
    
    func newWindow() {
        let win = Window(manager: self)
        
        /// IMPORTANT: while the window classes manager has the correct id unless you feed in the browser for the environment it will not use it properly and regenerate it
        let hostingController = NSHostingController(rootView: WindowView(window: win).environment(\.browser, self).frame(width: 400, height: 400))
        
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 400))
        window.orderFront(nil)
        
        self.windows.append(win)
        print(windows)
    }
}

@Observable
class Space: Identifiable {
    var id = UUID()
    var title: String
    var manager: Browser
    
    var pinnedId = UUID()
    var pinned: [TabRepresentation] = []
    
    var unpinnedId = UUID()
    var unpinned: [TabRepresentation] = []
    
    init(manager: Browser) {
        self.manager = manager
        self.title = ""
    }
    
    func removeTab(tab: TabRepresentation) {
        self.pinned.removeAll(where: { $0 == tab })
        self.unpinned.removeAll(where: { $0 == tab })
    }
}


