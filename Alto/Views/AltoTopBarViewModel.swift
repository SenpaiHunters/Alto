import SwiftUI



@Observable
class AltoTopBarViewModel {
    var state: AltoState
    var topbarState: TopbarState = .hidden
    var currentTab: AltoTab? {
        return state.browserTabsManager.currentSpace.currentTab
    }
    
    enum TopbarState {
        case hidden, active
    }
    
    init(state: AltoState) {
        self.state = state
    }
}


struct AltoTopBar: View {
    var model: AltoTopBarViewModel
    
    var body: some View {
        
            HStack {
                // MacButtonsViewNew()
                MacButtonsView()
                    .padding(.leading, 6)
                    .frame(width: 70)
                
                // ToDo: add spaces dropdown
                AltoButton(action: {
                    model.currentTab?.webView.goBack()
                }, icon: "arrow.left", active: model.currentTab?.canGoBack ?? false)

                AltoButton(action: {
                    model.currentTab?.webView.goForward()
                }, icon: "arrow.right", active: model.currentTab?.canGoForward ?? false)

                DragAndDropView(DragAndDropViewModel(state: model.state, tabLocation: model.state.browserTabsManager.currentSpace.normal))
                
                TopBarRigtButtonsView()
            }
            .frame(height: 25)
    }
}
