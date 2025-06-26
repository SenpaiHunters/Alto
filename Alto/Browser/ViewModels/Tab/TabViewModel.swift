import Observation
import OpenADK
import SwiftUI

@Observable
class TabViewModel {
    var state: AltoState
    var tab: TabRepresentation
    var draggingViewModel: DropZoneViewModel
    var tabManager: AltoTabsManager? {
        state.tabManager as? AltoTabsManager
    }

    var altoTab: ADKTab? {
        AltoData.shared.getTab(id: tab.id)
    }

    var tabTitle: String {
        altoTab?.content[0].title ?? "Untitled"
    }

    var tabIcon: Image {
        if let favicon = altoTab?.content[0].favicon {
            Image(nsImage: favicon)
        } else {
            Image(systemName: "square.fill")
        }
    }

    var closeIcon = Image(systemName: "xmark")

    var isHovered = false
    var isDragged = false

    var isCurrentTab: Bool {
        tabManager?.currentSpace?.currentTab?.id == altoTab?.id
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
        tabManager?.currentSpace?.currentTab = AltoData.shared.getTab(id: tab.id)
        tabManager?.currentTab = AltoData.shared.getTab(id: tab.id)
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
