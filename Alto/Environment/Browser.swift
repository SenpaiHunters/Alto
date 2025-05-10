//
//  Browser.swift
//  Alto
//
//  Created by Henson Liga on 5/9/25.
//

import SwiftUI
import Observation
import AppKit


extension EnvironmentValues {
    /// Provides access to the shared `Browser` instance in the SwiftUI environment.
    @Entry var browser: Browser = Browser()
}

/// This handles any data that needs to be shared across all windows and subviews
@Observable
class Browser {
    /// this will keep track of browser windows
    var windows: [Window] = []
    
    /// holds all tab objects for reference via ID
    /// Tabs are shared between all windows
    /// If tabs are held inside other tabs it requires recursion to find and deleat them
    /// this way all you need is an ID an you can look up the tab
    var tabs: [Tab] = [Tab(title: "tab 1")]
    
    /// Favorite tabs
    var favoritesId = UUID()
    var favorites: [TabItem] = []
    
    /// Spaces
    var spaces: [String] = []
    
    init() {
        /// Use a function to pull from a stored json
        self.windows = []
        /// Use a function to pull from a stored json
        self.tabs = []
        
        self.tabs.append(Tab(title: "tab 1"))
        self.tabs.append(Tab(title: "tab 2"))
        self.tabs.append(Tab(title: "tab 3"))
        
        /// for every tab object it creates a tab item that is dragable
        for (index, tab) in tabs.enumerated() {
            self.favorites.append(TabItem(id: tab.id, title: "Tab 0", favicon: ""))
        }

       
        /// In the case there are no windows pulled from memory it will make a new one
        if self.windows.count < 1 {
            self.windows.append(Window(manager: self))
        }
    }
    
    /// Opens a new browser window with a WindowView
    func openNewWindow() {
        let windowController = WindowController(rootView: WindowView(window: Window(manager: self)))
        windowController.window?.title = "Child Window \(1)"
        windowController.showWindow(nil)
    }
    
    /// Gets a tab object from its ID
    func tabFromId(_ id: UUID) -> String {
        if let tab = tabs.first(where: { $0.id == id}) {
            return tab.title
        }
        return "No Tab Found"
    }
}

struct Tab: Identifiable {
    var id: UUID = UUID()
    var title: String
}

/// This code comes from: https://blog.rampatra.com/how-to-open-a-new-window-in-swiftui
/// Creates a new window with a view
class WindowController<RootView: View>: NSWindowController {
    convenience init(rootView: RootView) {
        let hostingController = NSHostingController(rootView: rootView.frame(width: 400, height: 400))
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 400))
        self.init(window: window)
    }
}

/// This handles any window specific information like the specific space that is open, windows size and position
@Observable
class Window {
    var id = UUID()
    var manager: Browser  // uses the browser environment for managment
    
    init(manager: Browser) {
        self.manager = manager
    }
}

/// This is a temporary window view for testing
struct WindowView: View {
    var window: Window /// takes window class for handling the view

    var body: some View {
        VStack {
            Text(window.id.uuidString)
            
            /// Temporary button to test window system
            Button {
                window.manager.openNewWindow()
            } label: {
                Text("New Window")
            }
            
            /// Temporary drag and drop view for testing
            DragAndDropView()
        }
    }
}

