//
import Observation
import OpenADK
import SwiftUI

@Observable
class HoverZoneViewModel {
    enum ZonePlacement {
        case start
        case central
        case end
    }

    var tabLocation: TabLocationProtocol
    var state: AltoState
    var placement: ZonePlacement
    var index: Int

    var isTargeted = false

    var width: CGFloat {
        if placement == .start {
            return 20
        }
        return 40
    }

    var offset: CGSize {
        if placement == .start {
            return CGSize(width: 10, height: 0)
        }
        return CGSize(width: 0, height: 0)
    }

    init(state: AltoState, tabLocation: TabLocation, index: Int = 0, placement: ZonePlacement = .central) {
        self.state = state
        self.tabLocation = tabLocation
        self.placement = placement
        self.index = index

        if index == tabLocation.tabs.count {
            print("EQUAL COUNT")
            self.placement = .end
        }
    }

    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        /// this goes through each item from the dropped payload
        for tab in droppedTabs {
            if let location = Alto.shared.getTab(id: tab.id)?.location {
                location.removeTab(id: tab.id)
                Alto.shared.getTab(id: tab.id)?.location = tabLocation

                if tab.index < index {
                    tabLocation.tabs.insert(TabRepresentation(id: tab.id, index: index - 1), at: index - 1)
                } else {
                    tabLocation.tabs.insert(TabRepresentation(id: tab.id, index: index), at: index)
                }
            }
        }
        tabLocation.tabs = Array(tabLocation.tabs.uniqued())
        var tabsNew: [TabRepresentation] = []

        for (index, tab) in Array(tabLocation.tabs.enumerated()) {
            tabsNew.append(TabRepresentation(id: tab.id, containerID: tab.containerID, index: index - 1))
        }

        tabLocation.tabs = tabsNew
        return true
    }

    func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        isTargeted = targeted
    }
}
