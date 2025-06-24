//
import Observation

@Observable
class AltoTopBarViewModel {
    var state: AltoState
    var topbarState: TopbarState = .hidden

    enum TopbarState {
        case hidden
        case active
    }

    init(state: AltoState) {
        self.state = state
    }
}
