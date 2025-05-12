// Code based on this video:
// https://youtu.be/lsXqJKm4l-U?si=RxhoNdiyY2cruIUV

import Algorithms
import SwiftUI
import UniformTypeIdentifiers

/// Temporary View to test Drag and drop
struct DragAndDropView: View {
    @Environment(\.browser) private var browser
    
    /// stores the tab items for each drop zone
    @State private var unpinnedTabs: [TabRepresentation] = [
        
    ]
    @State private var pinnedTabs: [TabRepresentation] = []
    @State private var favoriteTabs: [TabRepresentation] = []

    /// used to detect when the drop zone is targeted and needs to display diferently
    @State private var isUnpinnedTargeted: Bool = false
    @State private var isPinnedTargeted: Bool = false
    @State private var isFavoriteTargeted: Bool = false

    
    var body: some View {
        VStack {
            DropZoneView(tabItems: unpinnedTabs, isTargeted: isUnpinnedTargeted)
                .dropDestination(for: TabRepresentation.self) { droppedTabs, location in

                    /// this goes through each item from the dropped payload
                    for tab in droppedTabs {
                        pinnedTabs.removeAll(where: { $0 == tab })
                        browser.favorites.removeAll(where: { $0 == tab })
                    }

                    /// ensures there are no duplicates of the dropped tabs
                    let allTabs = unpinnedTabs + droppedTabs
                    unpinnedTabs = Array(allTabs.uniqued())
                    return true
                } isTargeted: { isTargeted in
                    isUnpinnedTargeted = isTargeted
                }
            DropZoneView(tabItems: pinnedTabs, isTargeted: isPinnedTargeted)
                .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                    
                    /// this goes through each item from the dropped payload
                    for tab in droppedTabs {
                        unpinnedTabs.removeAll(where: { $0 == tab })
                        browser.favorites.removeAll(where: { $0 == tab })
                    }

                    /// ensures there are no duplicates of the dropped tabs
                    let allTabs = pinnedTabs + droppedTabs
                    pinnedTabs = Array(allTabs.uniqued())
                    return true
                } isTargeted: { isTargeted in
                    isPinnedTargeted = isTargeted
                }
            DropZoneView(tabItems: browser.favorites, isTargeted: isFavoriteTargeted)
                .dropDestination(for: TabRepresentation.self) { droppedTabs, location in

                    /// this goes through each item from the dropped payload
                    for tab in droppedTabs {
                        unpinnedTabs.removeAll(where: { $0 == tab })
                        pinnedTabs.removeAll(where: { $0 == tab })
                    }

                    /// ensures there are no duplicates of the dropped tabs
                    let allTabs = browser.favorites + droppedTabs
                    browser.favorites = Array(allTabs.uniqued())
                    return true
                } isTargeted: { isTargeted in
                    isFavoriteTargeted = isTargeted
                }
        }
    }
}

#Preview {
    DragAndDropView()
}

/// The drop zone handles rendering the items within the zone
struct DropZoneView: View {
    @Environment(\.browser) private var browser
    
    let tabItems: [TabRepresentation]
    let isTargeted: Bool

    var body: some View {
        ZStack {
            Rectangle()
                .fill(isTargeted ? .red : .blue)

            VStack {

                // this renders each tab from tabItems that are given to the dropzone
                ForEach(tabItems, id: \.id) { tab in
                    Text(browser.tabFromId(tab.id))
                        .draggable(tab)
                }
            }
        }
        .frame(width: 150, height: 50)
    }
}

/// A structure to store the tab data for drag and drop
struct TabRepresentation: Transferable, Codable, Comparable, Hashable {
    var id: UUID
    var title: String
    var favicon: String

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
