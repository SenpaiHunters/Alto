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
                    ForEach(Array(altoState.browserTabsManager!.tabs.enumerated()), id: \.element.id) {
                        index, tab in
                        dummyTabButtonView(tab: tab)
                    }
                }
                if let manager = altoState.browserTabsManager {
                    if let webView = manager.currentTab?.webView {
                        NSWebView(webView: webView)
                            .id(manager.currentTab?.id)
                    }
                }
            }
        }.ignoresSafeArea()
    }
}


/// A dummy Tab View for testing
struct dummyTabButtonView: View {
    @Environment(AltoState.self) private var altoState
    var tab: AltoTab
    var body: some View {
        Button(action: { altoState.browserTabsManager?.currentTab = tab }) {
            Text("Tab")
        }
    }
}


/// Allows the Appkit native WKWebView to be used in SwiftUI
struct NSWebView: NSViewRepresentable {
    var webView: AltoWebView

    func makeNSView(context: Context) -> WKWebView {
        return webView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {

    }
}
