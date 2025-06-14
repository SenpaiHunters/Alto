
import Algorithms
import SwiftUI
import UniformTypeIdentifiers
import Observation


@Observable
class DropZoneViewModel {
    var tabLocation: TabLocation
    var state: AltoState
    
    var isTargeted: Bool = false
    
    var displayedTabs: [TabRepresentation] {
        self.tabLocation.tabs
    }
    
    var isEmpty: Bool {
        return self.tabLocation.tabs.count == 0
    }
    
    init(state: AltoState, tabLocation: TabLocation) {
        self.state = state
        self.tabLocation = tabLocation
    }
    
    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        if self.isEmpty {
            
            /// this goes through each item from the dropped payload
            for tab in droppedTabs {
                if let location = Alto.shared.getTab(id: tab.id)?.location {
                    location.removeTab(id: tab.id)
                    Alto.shared.getTab(id: tab.id)?.location = tabLocation
                }
            }
            
            /// ensures there are no duplicates of the dropped tabs
            let allTabs = tabLocation.tabs + droppedTabs
            tabLocation.tabs = Array(allTabs.uniqued())
        }
        return true
    }
    
    func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        self.isTargeted = targeted
    }
}


