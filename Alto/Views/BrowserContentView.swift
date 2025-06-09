

import SwiftUI
struct BrowserContentView: View {
    @Environment(AltoState.self) private var altoState
    
    var body: some View {
        ZStack {
            VStack (spacing: 5) {
                HStack {
                    MacButtonsView() // ToDo: replace this with actual nsbuttons
                        .frame(width: 70)
                    DragAndDropView(DragAndDropViewModel(state: altoState, tabLocation: altoState.browserTabsManager.currentSpace.normal))
                    
                    TopBarRigtButtonsView()
                }
                .frame(height: 25)
                
                NSWebView(webView: altoState.browserTabsManager.currentSpace.currentTab?.webView)
                    .id(altoState.browserTabsManager.currentSpace.currentTab?.id)
                    .cornerRadius(5)
            }
            .padding(5)
        }
        .ignoresSafeArea()
    }
}

struct AltoDragAndDropView: View {
    
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
    }
}
