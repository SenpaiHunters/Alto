import SwiftUI

/// Allows the Appkit native WKWebView to be used in SwiftUI
struct NSWebView: NSViewRepresentable {
    var webView: AltoWebView?

    func makeNSView(context: Context) -> NSView {
        let VisualEffect = NSVisualEffectView()
        VisualEffect.material = .fullScreenUI
        VisualEffect.state = .active
        VisualEffect.blendingMode = .behindWindow

        return webView ?? VisualEffect /// Returns a Visual Effect for an empty View
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}
}
