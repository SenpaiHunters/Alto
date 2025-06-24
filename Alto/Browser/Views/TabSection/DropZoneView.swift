//
import OpenADK
import SwiftUI

struct DropZoneView: View {
    var model: DropZoneViewModel

    var body: some View {
        HStack {
            if let tabLocation = model.tabLocation as? TabLocation {
                hoverZoneView(model: HoverZoneViewModel(
                    state: model.state,
                    tabLocation: tabLocation,
                    placement: .start
                ))
            }

            ForEach(Array(model.displayedTabs.enumerated()), id: \.element.id) { index, tabItem in
                AltoTabView(model: TabViewModel(state: model.state, draggingViewModel: model, tab: tabItem))
                if let tabLocation = model.tabLocation as? TabLocation {
                    hoverZoneView(model: HoverZoneViewModel(
                        state: model.state,
                        tabLocation: tabLocation,
                        index: index + 1
                    ))
                }
            }

            Spacer()
        }
        .animation(.snappy(duration: 0.15), value: model.displayedTabs)
    }
}
