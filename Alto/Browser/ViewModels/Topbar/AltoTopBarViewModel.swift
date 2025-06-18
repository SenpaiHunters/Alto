//

@Observable
class AltoTopBarViewModel {
    var state: AltoState
    var topbarState: TopbarState = .hidden
    var currentTab: AltoTab? {
        state.browserTabsManager.currentSpace.currentTab
    }

    enum TopbarState {
        case hidden
        case active
    }

    init(state: AltoState) {
        self.state = state
    }
}
