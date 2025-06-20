//
import Observation
import OpenADK

// MARK: - AltoState

@Observable
@MainActor
class AltoState: GenaricState {
    var sidebar: Bool = false
//    The Command Palette needs to be visible on startup due to the Browser Spec
    var isShowingCommandPalette: Bool = true
    var Topbar: AltoTopBarViewModel.TopbarState = .active
    var draggedTab: TabRepresentation?

    func toggleTopbar() {
        switch Topbar {
        case .hidden:
            Topbar = .active
        case .active:
            Topbar = .hidden
        }
    }
}

// MARK: - AltoTab

@Observable
class AltoTab: GenaricTab {}
