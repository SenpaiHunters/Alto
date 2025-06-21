//
//  DragAndDropViewModel.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Algorithms
import Observation
import OpenADK
import SwiftUI
import UniformTypeIdentifiers

@Observable
class DropZoneViewModel {
    var tabLocation: any TabLocationProtocol
    let state: AltoState
    var isTargeted = false

    var displayedTabs: [TabRepresentation] { tabLocation.tabs }
    var isEmpty: Bool { tabLocation.tabs.isEmpty }

    init(state: AltoState, tabLocation: any TabLocationProtocol) {
        self.state = state
        self.tabLocation = tabLocation
    }

    func onDrop(droppedTabs: [TabRepresentation], location: CGPoint) -> Bool {
        guard isEmpty else { return true }

        for tab in droppedTabs {
            guard let currentLocation = Alto.shared.getTab(id: tab.id)?.location,
                  let altoTab = Alto.shared.getTab(id: tab.id) else { continue }

            currentLocation.removeTab(id: tab.id)
            altoTab.location = tabLocation
        }

        tabLocation.tabs = Array((tabLocation.tabs + droppedTabs).uniqued())
        return true
    }

    func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        isTargeted = targeted
    }
}
