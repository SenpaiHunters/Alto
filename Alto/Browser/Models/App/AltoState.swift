//
import Observation
import OpenADK

// MARK: - AltoState

@Observable
class AltoState: GenaricState {
    var sidebar = false
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
