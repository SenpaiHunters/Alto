import SwiftUI


struct dummyView: View {
    @Environment(WindowInfo.self) private var windowInfo
    @Environment(AltoState.self) private var altoState
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.clear)
            VStack {
                #if DEVELOPMENT
                Text("Window id: \(windowInfo.id)" )
                #endif
                Text("Sidebar: \(altoState.sidebar)" )
                Button {
                    AltoData.shared.windowManager.createWindow()
                } label: {
                    Text("New Window")
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


struct NSWebView: NSViewRepresentable {
    var webView: AltoWebView

    func makeNSView(context: Context) -> WKWebView {
        return webView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {

    }
}
