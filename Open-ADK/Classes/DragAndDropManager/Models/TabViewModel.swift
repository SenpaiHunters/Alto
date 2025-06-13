import SwiftUI


@Observable
class TabViewModelOld {
    var state: AltoState
    var tab: TabRepresentation
    var onDragStart: (() -> Void)?
    var isHovered: Bool = false
    var isDragged: Bool = false
    var tabTitle: String {
        Alto.shared.getTab(id: tab.id)?.title ?? "Untitled"
    }
    var tabIcon: Image {
        Alto.shared.getTab(id: tab.id)?.favicon ?? Image(systemName: "square.fill")
    }
    
    var altoTab: AltoTab? {
        return Alto.shared.getTab(id: tab.id)
    }
    
    var closeIcon: Image = Image(systemName: "xmark")
    var showCloseIcon: Bool {
        if isHovered && !isDragged {
            print("is closing true")
            return true
        }
        print("is closing false")
        return false
    }
    
    init(state: AltoState, tab: TabRepresentation, onDragStart: (() -> Void)? = nil) {
        self.state = state
        self.tab = tab
        self.onDragStart = onDragStart
    }
    
    func handleSingleClick() {
        self.state.browserTabsManager.currentSpace.currentTab = Alto.shared.getTab(id: self.tab.id)
        print("Tab Clicked")
        self.handleDragStart()
    }
    
    func handleDoubleClick() {
        print("Double Click")
    }
    
    func handleDragEnd() {
        print("hanlded end")
        self.isDragged = false
    }
    
    func handleDragStart() {
        print("hanlded start")
        self.state.browserTabsManager.currentSpace.currentTab = Alto.shared.getTab(id: self.tab.id)
        self.onDragStart?()
        self.isDragged = true
    }
    
    func handleClose() {
        self.altoTab?.closeTab()
    }
}



@Observable
class TabViewModel {
    var state: AltoState
    var tab: TabRepresentation
    var draggingViewModel: DropZoneViewModel
    
    var altoTab: AltoTab? {
        return Alto.shared.getTab(id: tab.id)
    }
    
    var tabTitle: String {
        Alto.shared.getTab(id: tab.id)?.title ?? "Untitled"
    }
    
    var tabIcon: Image {
        Alto.shared.getTab(id: tab.id)?.favicon ?? Image(systemName: "square.fill")
    }
    
    var closeIcon: Image = Image(systemName: "xmark")
    
    var isHovered: Bool = false
    var isDragged: Bool = false
    
    
    init(state: AltoState, draggingViewModel: DropZoneViewModel, tab: TabRepresentation) {
        self.state = state
        self.draggingViewModel = draggingViewModel
        self.tab = tab
    }
    
    func handleSingleClick() {
        state.browserTabsManager.currentSpace.currentTab = Alto.shared.getTab(id: tab.id)
    }
    
    func handleDoubleClick() {
        // Does nothing currenlty
        // Eventualy this will open a urlbar
    }
    
    func handleDragEnd() {
        
    }
    
    func handleClose() {
        self.altoTab?.closeTab()
    }
}
