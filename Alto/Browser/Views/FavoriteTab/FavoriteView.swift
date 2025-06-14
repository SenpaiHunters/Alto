import SwiftUI



struct FavoriteView: View {
    var model: TabViewModel
    @State var isHovered: Bool = false
    var body: some View {
        HStack {
            model.tabIcon
                .resizable()
                .scaledToFit()
        }
        .padding(4)
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .draggable(model.tab) {
            Rectangle()
                .fill(.red)
                .opacity(1)
        }
        .gesture(
            TapGesture(count: 2).onEnded {
                
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                model.handleSingleClick()
            }
        )
        .background(
            Rectangle()
                .fill(.white.opacity(0.2))
                .cornerRadius(5)
        )
        .onHover { hovered in
            
        }
    }
}




struct AltoFavoriteView: View {
    var model: TabViewModel
    
    var body: some View {
        HStack {
            faviconImage(model: model)
        }
        .padding(4)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill((model.state.browserTabsManager.currentSpace.currentTab?.id == model.tab.id || model.isHovered ) ? .gray.opacity(0.4) : .gray.opacity(0))
        )
        .contentShape(Rectangle()) // Makes the background clickable
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
        .draggable(model.tab) {
            AltoTabViewDragged(model: model)
        }
    }
}
