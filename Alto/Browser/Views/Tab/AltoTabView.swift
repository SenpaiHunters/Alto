//
import SwiftUI

struct AltoTabView: View {
    var model: TabViewModel

    var body: some View {
        HStack {
            faviconImage(model: model)

            Text(model.tabTitle)

            Spacer()

            closeButton(model: model)
        }
        .padding(4)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((model.state.browserTabsManager.currentSpace.currentTab?.id == model.tab.id || model.isHovered) ?
                    .gray.opacity(0.4) : .gray.opacity(0)
                ) // lol i need to fix this
        )
        .contentShape(Rectangle()) // added to the background clickable
        .gesture(
            TapGesture(count: 2).onEnded {
                model.handleDoubleClick()
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                model.handleSingleClick()
            }
        )
        .onHover { hovered in
            model.isHovered = hovered
        }
        .draggable(model.tab) {
            AltoTabViewDragged(model: model)
        }
    }
}
