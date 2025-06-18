import SwiftUI

@Observable
class TabViewModel {
    var state: AltoState
    var tab: TabRepresentation
    var draggingViewModel: DropZoneViewModel

    var altoTab: AltoTab? {
        Alto.shared.getTab(id: tab.id)
    }

    var tabTitle: String {
        Alto.shared.getTab(id: tab.id)?.title ?? "Untitled"
    }

    var tabIcon: Image {
        Alto.shared.getTab(id: tab.id)?.favicon ?? Image(systemName: "square.fill")
    }

    var closeIcon = Image(systemName: "xmark")

    var isHovered = false
    var isDragged = false

    var isCurrentTab: Bool {
        state.browserTabsManager.currentSpace.currentTab?.id == altoTab?.id
    }

    var tabRepresentation: TabRepresentation {
        tab
    }

    init(state: AltoState, draggingViewModel: DropZoneViewModel, tab: TabRepresentation) {
        self.state = state
        self.draggingViewModel = draggingViewModel
        self.tab = tab
    }

    func handleSingleClick() {
        state.browserTabsManager.currentSpace.currentTab = Alto.shared.getTab(id: tab.id)
    }

    func selectTab() {
        handleSingleClick()
    }

    func handleDoubleClick() {
        // Does nothing currenlty
        // Eventualy this will open a urlbar
    }

    func handleDragEnd() {}

    func handleClose() {
        altoTab?.closeTab()
    }
}
