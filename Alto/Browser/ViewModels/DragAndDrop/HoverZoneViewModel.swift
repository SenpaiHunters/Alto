//
//  HoverZoneViewModel.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
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
    let state: AltoState
    let index: Int
    private(set) var placement: ZonePlacement
    var isTargeted = false

    var width: CGFloat { placement == .start ? 20 : 40 }
    var offset: CGSize { placement == .start ? CGSize(width: 10, height: 0) : .zero }

    init(state: AltoState, tabLocation: TabLocation, index: Int = 0, placement: ZonePlacement = .central) {
        self.state = state
        self.tabLocation = tabLocation
        self.index = index
        self.placement = index == tabLocation.tabs.count ? .end : placement
    }

    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        for tab in droppedTabs {
            guard let currentLocation = Alto.shared.getTab(id: tab.id)?.location,
                  let altoTab = Alto.shared.getTab(id: tab.id) else { continue }

            currentLocation.removeTab(id: tab.id)
            altoTab.location = tabLocation

            let insertIndex = tab.index < index ? index - 1 : index
            tabLocation.tabs.insert(TabRepresentation(id: tab.id, index: insertIndex), at: insertIndex)
        }

        tabLocation.tabs = Array(tabLocation.tabs.uniqued())
            .enumerated()
            .map { TabRepresentation(id: $1.id, containerID: $1.containerID, index: $0 - 1) }

        return true
    }

    func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        isTargeted = targeted
    }
}
