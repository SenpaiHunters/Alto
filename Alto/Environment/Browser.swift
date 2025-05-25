
import SwiftUI
import Observation
import AppKit
import WebKit

/// allows browser class to be accsesed in all views
extension EnvironmentValues {
    @Entry var browser: Browser = Browser()
}

/// This handles any data that needs to be shared across all windows and subviews
@Observable
class Browser: Identifiable {
    /// this will keep track of browser windows
    var windows: [Window] = []
    var activeWindow: UUID?
#warning("FIX IT SO WHEN A WINDOW IS CLOSED IT IS REMOVED FROM THE WINDOWS ARRAY")
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
    
    enum TabTypes {
        case tab, folder, splitview, group, favorite
    }
    
    init() {
        
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
        self.setCrossSiteTracking(enabled: false)
    }
    
    func setCrossSiteTracking(enabled: Bool) {
        print("THIS RAN!!!!!!!!!!", enabled)
        WKWebsiteDataStore.nonPersistent()._setResourceLoadStatisticsEnabled(enabled)
        WKWebsiteDataStore.default()._setResourceLoadStatisticsEnabled(enabled)
    }
    
    func newTab(_ url: String = "https://www.google.com/", window: Window) {
        let newTab = Tab(self, url: URL(string: url))
        let newTabRepresentation = TabRepresentation(id: newTab.id, title: "Tab 0", favicon: "", url: newTab.url.absoluteString)
        self.tabs.append(newTab)
        self.getSpace().unpinned.append(newTabRepresentation)
        window.activeTab = newTabRepresentation
        print("New Tab!")
    }
    
    func newTab(_ tab: Tab, window: Window) {
        let newTabRepresentation = TabRepresentation(id: tab.id, title: "Tab 0", favicon: "", url: tab.url.absoluteString)
        self.tabs.append(tab)
        self.getSpace().unpinned.append(newTabRepresentation)
        window.activeTab = newTabRepresentation
        print("New Tab!")
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
    
    /// Gets the currently active window unless ID is specified
    func getWindow(id: UUID? = nil) -> Window {
        if id == nil {
            let window = windows.first(where: { $0.id == activeWindow })
            if let window = window {
                print("window found", window.id)
                return window
            }
        } else {
            let returnedWindow = windows.first(where: { $0.id == id})
            return returnedWindow!
        }
        return windows[0]
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
        let hostingController = NSHostingController(rootView: WindowView(window: win).environment(\.browser, self).frame(width: 800, height: 500))
        
        let window = NSWindow(contentViewController: hostingController)
        win.nsWindow = window
        window.setContentSize(NSSize(width: 800, height: 500))
        window.orderFront(nil)
        
        self.windows.append(win)
        print(windows)
    }
    
    func convertTab(ids: [UUID], to tab: TabTypes) -> [TabItem]? {
        let returnedTab: TabItem
        
        for id in ids {
            tabs.removeAll(where: { $0.id == id })
        }
        
        let firstTab = tabFromId(ids[0])
        
        switch tab {
        case .favorite:
            /// takes: a tab and a favorite
            
            returnedTab = Favorite(self, url: firstTab?.url?.absoluteURL)
        case .folder:
            returnedTab = Folder(self, childrenIds: ids)
        case .group:
            returnedTab = Group(self, childrenIds: ids)
        case .splitview:
            returnedTab = SplitView(self, childrenIds: ids)
        case .tab:
            returnedTab = Tab(self)
        }
        
        
        return [returnedTab]
        //let newTab = Tab(self)
        // self.newTab(newTab)
        // remove existing tabs from id Array
        // create a new tab
    }
}
