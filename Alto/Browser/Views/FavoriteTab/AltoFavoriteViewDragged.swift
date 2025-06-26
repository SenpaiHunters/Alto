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
            
        )
        .onAppear(
            perform: {
                model.state.draggedTab = model.tab
                model.isDragged = true

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
