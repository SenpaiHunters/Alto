import SwiftUI

/// A dummy View for testing
struct dummyView: View {
    @Environment(WindowInfo.self) private var windowInfo
    @Environment(AltoState.self) private var altoState
    
    var body: some View {
        ZStack {
            WindowBackgroundView()
            VStack {
                #if DEVELOPMENT
                Text("Window id: \(windowInfo.id)" )
                #endif
                Text("Sidebar: \(altoState.sidebar)" )
                Button {
                    Alto.shared.windowManager.createWindow()
                } label: {
                    Text("New Window")
                }
                
                HStack {
                    Button {
                            altoState.browserTabsManager.spaceIndex = (altoState.browserTabsManager.spaceIndex + 1) % Alto.shared.spaces.count

                    } label: {
                        Text("Space Toggle")
                    }
                    
                    Spacer()

                        // DragAndDropView(DragAndDropViewModel(state: altoState, tabLocation: tabManager.favorites))
                        // DragAndDropView(DragAndDropViewModel(state: altoState, tabLocation: tabManager.currentSpace.pinned))
                        DragAndDropView(DragAndDropViewModel(state: altoState, tabLocation: altoState.browserTabsManager.currentSpace.normal))

                    
                    Button {
                        altoState.browserTabsManager.createNewTab()
                    } label: {
                        Text(" + ")
                    }
                }
                
                    if let webView = altoState.browserTabsManager.currentSpace.currentTab?.webView {
                        NSWebView(webView: webView)
                            .id(altoState.browserTabsManager.currentSpace.currentTab?.id)
                    } else {
                        Spacer()
                    }

            }
        }
    }
}


/// A dummy Tab View for testing
struct dummyTabButtonView: View {
    @Environment(AltoState.self) private var altoState
    var tab: AltoTab
    var body: some View {
        Button(action: { altoState.browserTabsManager.currentSpace.currentTab = tab }) {
            Text("Tab")
        }
    }
}

