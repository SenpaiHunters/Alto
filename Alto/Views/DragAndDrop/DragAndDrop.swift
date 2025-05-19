// Code based on this video:
// https://youtu.be/lsXqJKm4l-U?si=RxhoNdiyY2cruIUV

import Algorithms
import SwiftUI
import UniformTypeIdentifiers
import Observation

@Observable
class DragAndDropViewModel {
    var browser: Browser
    var containerId: UUID
    var window: Window
    
    init(browser: Browser, window: Window, containerId: UUID) {
        self.browser = browser
        self.containerId = containerId
        self.window = window
    }
    
    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        /// this goes through each item from the dropped payload
        for tab in droppedTabs {
            browser.removeTab(tab: tab)
        }

        /// ensures there are no duplicates of the dropped tabs
        let allTabs = browser.getTabs(id: containerId) + droppedTabs
        browser.setTabArray(containerId, tabs:Array(allTabs.uniqued()))
        return true
    }
}


struct DragAndDropView: View {
    @State var isZoneTargeted: Bool = false
    var model: DragAndDropViewModel
    
    init(_ model: DragAndDropViewModel) {
        self.model = model
    }
    
    var body: some View {
        DropZoneView(window: model.window, tabItems: model.browser.getTabs(id: model.containerId), isTargeted: isZoneTargeted)
            .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                model.onDrop(droppedTabs: droppedTabs, location: location)
            } isTargeted: { isTargeted in
                isZoneTargeted = isTargeted
            }
    }
}


/// The drop zone handles rendering the items within the zone
struct DropZoneView: View {
    @Environment(\.browser) private var browser
    var window: Window
    var tabItems: [TabRepresentation]
    @State var isTargeted: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isTargeted ? .red : .blue)

            if window.state == .topbar {
                HStack {
                    // this renders each tab from tabItems that are given to the dropzone
                    ForEach(tabItems, id: \.id) { tabItem in
                        if let tab = browser.tabFromId(tabItem.id), let title = tab.title {
                            TabView(TabViewModel(manager: browser,window:window, tab: tabItem, title: title))
                        }
                    }
                }
            } else {
                VStack {

                    // this renders each tab from tabItems that are given to the dropzone
                    ForEach(tabItems, id: \.id) { tabItem in
                        if let tab = browser.tabFromId(tabItem.id), let title = tab.title {
                            TabView(TabViewModel(manager: browser,window:window, tab: tabItem, title: title))
                        }
                    }
                }
            }
            
        }
        .frame(width: 150, height: 50)
    }
}

/// A structure to store the tab data for drag and drop
struct TabRepresentation: Transferable, Codable, Comparable, Hashable, Identifiable {
    var id: UUID
    var title: String = "unloaded"
    var favicon: String = "square"
    var url: String

    /// tells the struct it should be represented as the custom UTType .tabItem
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .tabItem)
    }

    /// allows the tabs to be comparied with eachother based on ID
    static func < (lhs: TabRepresentation, rhs: TabRepresentation) -> Bool {
        return lhs.id == rhs.id
    }
}

/// extentds the Unifide type identifier to add the tabItem structure
extension UTType {
    static let tabItem = UTType(exportedAs: "Alto-Browser.Alto.tabItem")
    /// creates a exported type identiffier
}


