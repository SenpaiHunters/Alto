import SwiftUI



class TabViewModel {
    var state: AltoState
    var tab: TabRepresentation
    var onDragStart: (() -> Void)?
    var tabTitle: String {
        Alto.shared.getTab(id: tab.id).title
    }
    var tabIcon: Image {
        Alto.shared.getTab(id: tab.id).favicon ?? Image(systemName: "square")
    }
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
}

struct TabView: View {
    var model: TabViewModel
    var body: some View {
            HStack {
                model.tabIcon
                    .resizable()
                    .scaledToFit()
                Text(model.tabTitle)
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
