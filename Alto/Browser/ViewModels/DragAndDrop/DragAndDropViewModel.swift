
import Algorithms
import Observation
import OpenADK
import SwiftUI
import UniformTypeIdentifiers

@Observable
class DropZoneViewModel {
    var tabLocation: any TabLocationProtocol
    var state: AltoState

    var isTargeted = false

    var displayedTabs: [TabRepresentation] {
        tabLocation.tabs
    }

    var isEmpty: Bool {
        tabLocation.tabs.isEmpty
    }

    init(state: AltoState, tabLocation: any TabLocationProtocol) {
        self.state = state
        self.tabLocation = tabLocation
    }

    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        if isEmpty {
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
        isTargeted = targeted
    }
}
