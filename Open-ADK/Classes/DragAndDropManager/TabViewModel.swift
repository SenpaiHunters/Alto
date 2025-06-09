import SwiftUI



class TabViewModel {
    var state: AltoState
    var tab: TabRepresentation
    var onDragStart: (() -> Void)?
    var tabTitle: String {
        Alto.shared.getTab(id: tab.id)?.title ?? "Untitled"
    }
    var tabIcon: Image {
        Alto.shared.getTab(id: tab.id)?.favicon ?? Image(systemName: "square.fill")
    }
    
    var altoTab: AltoTab? {
        return Alto.shared.getTab(id: tab.id)
    }
    
    var closeIcon: Image = Image(systemName: "xmark")
    
    init(state: AltoState, tab: TabRepresentation, onDragStart: (() -> Void)? = nil) {
        self.state = state
        self.tab = tab
        self.onDragStart = onDragStart
    }
    
    func handleSingleClick() {
        self.state.browserTabsManager.currentSpace.currentTab = Alto.shared.getTab(id: self.tab.id)
        print("Tab Clicked")
        self.handleDragStart()
    }
    
    func handleDoubleClick() {
        print("Double Click")
    }
    
    func handleDragStart() {
        self.onDragStart?()
    }
    
    func handleClose() {
        self.altoTab?.closeTab()
    }
}

struct TabView: View {
    var model: TabViewModel
    @State var isHovered: Bool = false
    var body: some View {
            HStack {
                model.tabIcon
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(5)
                Text(model.tabTitle)
                
                Spacer()
                
                Button(action:{model.handleClose()}) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isHovered ? .gray.opacity(0.1) : .gray.opacity(0))
                        model.closeIcon
                    }
                    .animation(.bouncy, value: isHovered)
                    .onHover { hovered in
                        isHovered = hovered
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .aspectRatio(1/1, contentMode: .fit)
            }
            .padding(4)
            .frame(width: 150)
            .contentShape(Rectangle())
            .draggable(model.tab) {
                Rectangle()
                    .opacity(0)
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
                    .opacity(0)
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
