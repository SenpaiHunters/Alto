//
//  Browser.swift
//  Alto
//
//  Created by Henson Liga on 5/9/25.
//

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
    var tabs: [TabItem] = []
    
    var favoritesId = UUID()
    var favorites: [TabRepresentation] = []
    
    var spaces: [String] = []
    
    init() {
        print("Browser Init")
        /// Use a function to pull from a stored json
        self.windows = []
        /// Use a function to pull from a stored json
        self.tabs = []
        
        /// this adds tabs on init for testing perposes
        self.tabs.append(Tab(self))
        
        
        /// for every tab object it creates a tab item that is dragable
        for (_, tab) in tabs.enumerated() {
            self.favorites.append(TabRepresentation(id: tab.id, title: "Tab 0", favicon: ""))
        }

       
        /// In the case there are no windows pulled from memory it will make a new one
        if self.windows.count < 1 {
            self.windows.append(Window(manager: self))
        }
    }
    
    /// Gets a tab object from its ID
    func tabFromId(_ id: UUID) -> String {
        if let tab = tabs.first(where: { $0.id == id}) {
            print(tab.title)
            return tab.title
        }
        return "No Tab Found"
    }
    
    func removeTab(tab: TabRepresentation) {
        print(tab)
        self.favorites.removeAll(where: { $0 == tab })
    }
    
    func getTabs() -> [TabRepresentation] {
        print("FAVS:", favorites)
        print("browser id:", id)
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

/// This handles any window specific information like the specific space that is open, windows size and position
@Observable
class Window: Identifiable {
    var id = UUID()
    var title: String
    var manager: Browser  // uses the browser environment for managment
    
    init(manager: Browser) {
        self.manager = manager
        self.title = ""
    }
}

