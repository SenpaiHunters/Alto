//

import Observation

@Observable
class Space {
    var pinned = TabLocation()
    var normal = TabLocation()

    var currentTab: AltoTab? // maybe make this computed in the future
    // add a theme variable
}
