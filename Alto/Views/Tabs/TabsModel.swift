
import SwiftUI

// This is for normal tabs, all other tabs inharit theses properties
class TabItem: Identifiable, Comparable {
    var id: UUID = UUID()
    /// The ID of the section like pinned tabs or a folder
    var parentID: UUID?
    var title: String
    var icon: Image?
    
    /// This allows the tabs to preform actions like closing other tabs
    var manager: Browser
    
    init(_ manager: Browser, title: String = "Temp Title", icon: Image? = nil) {
        self.title = title
        self.icon = icon
        self.manager = manager
    }
    
    /// allows TabItem to conform to Equatable using IDs
    static func < (lhs: TabItem, rhs: TabItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// allows TabItem to conform to Comparable using IDs
    static func == (lhs: TabItem, rhs: TabItem) -> Bool {
        return lhs.id == rhs.id
    }
}

/// Normal Tab
class Tab: TabItem {
    var url: URL
    var webviewManager: WebViewManager
    
    init(_ manager: Browser, url: URL? = nil) {
        let resolvedURL = url ?? URL(string: "https://www.google.com/")!
        self.url = resolvedURL
        self.webviewManager = WebViewManager(manager: manager, url: resolvedURL.absoluteString)
        super.init(manager)
        
    }
}

/// Tab Folder
class Folder: TabItem {
    var childrenIds: [UUID]
    
    init(_ manager: Browser, childrenIds: [UUID] = []) {
        self.childrenIds = childrenIds
        
        super.init(manager)
    }
}

/// Split View
class SplitView: TabItem {
    var childrenIds: [UUID]
    
    init(_ manager: Browser, childrenIds: [UUID] = []) {
        self.childrenIds = childrenIds
        
        super.init(manager)
    }
}

/// Tab Group, this will only allow tabs that are not folders and are like the auto sorted groups used by Arc Max
class Group: TabItem {
    var childrenIds: [UUID]
    
    init(_ manager: Browser, childrenIds: [UUID] = []) {
        self.childrenIds = childrenIds
        
        super.init(manager)
    }
}

/// Favorites reset to the base URL when double clicked and are active across mutliple Spaces
class Favorite: TabItem {
    var url: URL
    var baseURL: URL
    
    init(_ manager: Browser, baseURL: URL) {
        self.url = baseURL
        self.baseURL = baseURL
        super.init(manager)
    }
}
