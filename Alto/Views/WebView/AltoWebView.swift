//

import Foundation
import SwiftUI
import WebKit

@objc class AltoWebView: WKWebView {
    var currentConfiguration: WKWebViewConfiguration
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        currentConfiguration = configuration
        WKWebsiteDataStore.nonPersistent()._setResourceLoadStatisticsEnabled(false)
        WKWebsiteDataStore.default()._setResourceLoadStatisticsEnabled(false)

        super.init(frame: frame, configuration: configuration)
        

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    public override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        print("Test")

    }

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        print("opened menu")
        
        let menuItem = NSMenuItem(
            title: "Kill YOu rSelf",
            action: #selector(menuItemClicked),
            keyEquivalent: "P"
        )
        menuItem.target = self

        menu.items = [
            menuItem
        ]
    }
    
    @objc func menuItemClicked() {
        print("Kill YOu rSelf!")
    }
}



/*
 // This is for ALL tabs, all other tabs inherate these properties
 // may not have a WebView, could contain other tabs
 class AltoItem: Identifiable, Comparable {
     var id: UUID = UUID()
     /// The ID of the section like pinned tabs or a folder
     var manager: Browser
     var parentID: UUID?
     var name: String
     var icon: Image?
     var tabState: TabState = .unpinned
     var space: Space?
     var profile: String? // temperary
     
     init(_ manager: Browser, space: Space? = nil, state: TabState, name: String = "Temp Title", icon: Image? = nil) {
         self.name = name
         self.icon = icon
         self.manager = manager
         self.space = space
         if space == nil {
             self.tabState = .favorited
         }
     }
     
     /// allows TabItem to conform to Equatable using IDs
     static func < (lhs: AltoItem, rhs: AltoItem) -> Bool {
         return lhs.id == rhs.id
     }
     
     /// allows TabItem to conform to Comparable using IDs
     static func == (lhs: AltoItem, rhs: AltoItem) -> Bool {
         return lhs.id == rhs.id
     }
     
     func pinTab(to: TabState) {
         
     }
 }

 // Base unit used for everything else
 class NormalTab: AltoItem, Pinnable, Favoriteable {
     
 }

 class Folder: AltoItem, Pinnable {
     
 }

 class SplitView: AltoItem, Pinnable, Favoriteable {
     
 }

 enum TabState {
     case unpinned, pinned, favorited
 }

 protocol Pinnable {
     
 }

 protocol Favoriteable {
     
 }

 */
