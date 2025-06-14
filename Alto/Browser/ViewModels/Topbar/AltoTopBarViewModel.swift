//



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