//
import Observation
import OpenADK

// MARK: - AltoState

@Observable
public class AltoState: ADKState {
    var sidebar = true
    var sidebarIsRight = false
//    The Command Palette needs to be visible on startup due to the Browser Spec
    var isShowingCommandPalette = true
    var Topbar: AltoTopBarViewModel.TopbarState = .hidden
    var draggedTab: TabRepresentation?

    public init() {
        let altoManager = AltoTabsManager()
        altoManager.currentSpace = AltoData.shared.spaces[0]

        super.init(tabManager: altoManager)
    }

    func toggleTopbar() {
        switch Topbar {
        case .hidden:
            Topbar = .active
        case .active:
            Topbar = .hidden
        }
    }
}
