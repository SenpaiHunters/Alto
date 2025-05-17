
import SwiftUI
import Observation

@Observable
class TabItemViewModel {
    var manager: Browser
    var favicon: Image = Image(systemName: "square")
    var title: String = ""
    var tab: TabRepresentation
    
    init(_ manager: Browser, tab: TabRepresentation, title: String = "") {
        self.manager = manager
        self.tab = tab
        ///self.favicon =
        self.title = title
    }
    
    func handleSingleClick() {
        self.manager.activeTab = self.tab
        print("Tab Clicked")
    }
    
    func handleDoubleClick() {
        print("Double Click")
    }
}

class TabViewModel: TabItemViewModel {
    
    init(manager: Browser, tab: TabRepresentation, title: String = "") {
        super.init(manager, tab: tab, title:title)
    }
}

struct TabView: View {
    var model: TabViewModel

    init(_ model: TabViewModel) {
        self.model = model
    }
    
    var body: some View {
        Text(model.title)
            .draggable(model.tab)
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
    }
}
