//



import SwiftUI
import Observation

@Observable
class Space: Identifiable {
    var id = UUID()
    var title: String
    var manager: Browser
    
    var pinnedId = UUID()
    var pinned: [TabRepresentation] = []
    
    var unpinnedId = UUID()
    var unpinned: [TabRepresentation] = []
    
    init(manager: Browser) {
        self.manager = manager
        self.title = ""
    }
    
    func removeTab(tab: TabRepresentation) {
        self.pinned.removeAll(where: { $0 == tab })
        self.unpinned.removeAll(where: { $0 == tab })
    }
}


