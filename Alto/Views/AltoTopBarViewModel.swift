import SwiftUI



@Observable
class AltoTopBarViewModel {
    var state: AltoState
    var topbarState: TopbarState = .hidden
    var currentTab: AltoTab? {
        return state.browserTabsManager.currentSpace.currentTab
    }
    
    enum TopbarState {
        case hidden, active
    }
    
    init(state: AltoState) {
        self.state = state
    }
}


struct AltoTopBar: View {
    var model: AltoTopBarViewModel
    
    var body: some View {
            HStack {
                
                // MacButtonsViewNew()
                MacButtonsView()
                    .padding(.leading, 6)
                    .frame(width: 70)
                
                // ToDo: add spaces dropdown
                AltoButton(action: {
                    model.currentTab?.webView.goBack()
                }, icon: "arrow.left", active: model.currentTab?.canGoBack ?? false)
                .frame(height: 30)
                .fixedSize()
                
                AltoButton(action: {
                    model.currentTab?.webView.goForward()
                }, icon: "arrow.right", active: model.currentTab?.canGoForward ?? false)
                .frame(height: 30)
                .fixedSize()
                
                AltoFavoritesView(DragAndDropViewModel(state: model.state, tabLocation: model.state.browserTabsManager.favorites))
                    .frame(height: 30)
                    .fixedSize()
                
                if model.state.browserTabsManager.favorites.tabs.count > 0 {
                    Divider().frame(width: 2)
                }
                
                AltoNormalView(DragAndDropViewModel(state: model.state, tabLocation: model.state.browserTabsManager.currentSpace.normal))
                    .frame(maxWidth: .infinity)
                    .layoutPriority(1)
                
                TopBarRigtButtonsView()
                    .frame(height: 30)
                    .fixedSize()
            }
            .frame(height: 30)
    }
}



struct AltoFavoritesView: View {
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
                        FavoriteView(model: TabViewModel(state: model.state, tab: tabItem, onDragStart: {
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

struct AltoNormalView: View {
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
