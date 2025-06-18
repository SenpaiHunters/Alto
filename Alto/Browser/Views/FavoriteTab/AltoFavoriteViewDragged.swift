//

import SwiftUI

struct AltoFavoriteViewDragged: View {
    var model: TabViewModel

    var body: some View {
        HStack {
            faviconImage(model: model)

            Text(model.tabTitle)
                .draggable(model.tab)

            Spacer()
        }
        .padding(4)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((model.state.currentSpace?.currentTab?.id == model.tab.id || model.isHovered) ?
                    .gray.opacity(0.4) : .gray.opacity(0)
                )
        )
        .onAppear(
            perform: {
                model.state.draggedTab = model.tab
                model.isDragged = true
                model.state.currentSpace?.currentTab = model.altoTab
                print("drag start")
            }
        )
        .onDisappear(
            perform: {
                model.isDragged = false
                print("drag end")
            }
        )
    }
}
