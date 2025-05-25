//

import Foundation
import SwiftUI
import WebKit

@objc class AltoWebView: WKWebView {
    
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
