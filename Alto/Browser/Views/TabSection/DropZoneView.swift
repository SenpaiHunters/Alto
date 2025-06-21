import OpenADK
import SwiftUI

struct DropZoneView: View {
    let model: DropZoneViewModel

    var body: some View {
        HStack {
            tabContent
            Spacer()
        }
        .animation(.snappy(duration: 0.15), value: model.displayedTabs)
    }

    private var tabContent: some View {
        Group {
            hoverZone(placement: .start)

            ForEach(Array(model.displayedTabs.enumerated()), id: \.element.id) { index, tabItem in
                AltoTabView(model: TabViewModel(state: model.state, draggingViewModel: model, tab: tabItem))
                hoverZone(for: index + 1)
            }
        }
    }

    private func hoverZone(for index: Int? = nil, placement: HoverZoneViewModel.ZonePlacement = .central) -> some View {
        Group {
            if let tabLocation = model.tabLocation as? TabLocation {
                if let index {
                    HoverZoneView(model: HoverZoneViewModel(
                        state: model.state,
                        tabLocation: tabLocation,
                        index: index
                    ))
                } else {
                    HoverZoneView(model: HoverZoneViewModel(
                        state: model.state,
                        tabLocation: tabLocation,
                        placement: placement
                    ))
                }
            }
        }
    }
}
