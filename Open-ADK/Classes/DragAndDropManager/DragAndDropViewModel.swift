
import Algorithms
import SwiftUI
import UniformTypeIdentifiers
import Observation


@Observable
class DragAndDropViewModel {
    var tabLocation: TabLocation
    var state: AltoState
    
    init(state: AltoState, tabLocation: TabLocation) {
        self.state = state
        self.tabLocation = tabLocation
    }
    
    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        
        /// this goes through each item from the dropped payload
        for tab in droppedTabs {
            if var location = Alto.shared.getTab(id: tab.id)?.location {
                location.removeTab(id: tab.id)
                print("tab droped")
                print("old loc:", location.tabs)
                print("new loc:", tabLocation.tabs)
                Alto.shared.getTab(id: tab.id)?.location = tabLocation
                
                
            }
        }
        
        /// ensures there are no duplicates of the dropped tabs
        let allTabs = tabLocation.tabs + droppedTabs
        tabLocation.tabs = Array(allTabs.uniqued())
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
       
            HStack {
                let row = Array(repeating: GridItem(spacing: 1), count: 1)
                LazyHGrid(rows: row, spacing: 5) {
                    ForEach(model.tabLocation.tabs, id: \.id) { tabItem in
                        TabView(model: TabViewModel(state: model.state, tab: tabItem, onDragStart: {
                            model.state.draggedTab = tabItem
                        }))
                        .dropDestination(for: TabRepresentation.self) { item, location in
                            return false
                        } isTargeted: { status in
                            if let draggedTab = model.state.draggedTab {
                                if status, draggedTab != tabItem {
                                    if let sourceIndex = model.tabLocation.tabs.firstIndex(of: draggedTab),
                                       let destinationIndex = model.tabLocation.tabs.firstIndex(of: tabItem) {
                                        
                                        withAnimation(.smooth) {
                                            let sourceItem = model.tabLocation.tabs.remove(at: sourceIndex)
                                            model.tabLocation.tabs.insert(sourceItem, at: destinationIndex)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
                Spacer()
            }
            
            .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                model.onDrop(droppedTabs: droppedTabs, location: location)
            } isTargeted: { isTargeted in
                self.isZoneTargeted = isTargeted
            }
        
    }
}


/// A structure to store the tab data for drag and drop
struct TabRepresentation: Transferable, Codable, Comparable, Hashable, Identifiable {
    var id: UUID
    
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

