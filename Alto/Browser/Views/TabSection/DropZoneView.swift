//
import SwiftUI

struct DropZoneView: View {
    var model: DropZoneViewModel

    var body: some View {
        HStack {
            hoverZoneView(model: HoverZoneViewModel(
                state: model.state,
                tabLocation: model.tabLocation,
                placement: .start
            ))

            ForEach(Array(model.displayedTabs.enumerated()), id: \.element.id) { index, tabItem in
                AltoTabView(model: TabViewModel(state: model.state, draggingViewModel: model, tab: tabItem))
                hoverZoneView(model: HoverZoneViewModel(
                    state: model.state,
                    tabLocation: model.tabLocation,
                    index: index + 1
                ))
            }

            Spacer()
        }
        .animation(.snappy(duration: 0.15), value: model.displayedTabs)
    }
}
