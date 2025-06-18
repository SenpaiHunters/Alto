// MARK: - AltoWebView

/// Custom verson of WKWebView to avoid needing an extra class for managment
@Observable
class AltoWebView: WKWebView {
    #if DEVELOPMENT
        static var aliveWebViewsCount = 0
    #endif
    var currentConfiguration: WKWebViewConfiguration
    var delegate: WKUIDelegate?
    var navDelegate: WKNavigationDelegate?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        currentConfiguration = configuration
        super.init(frame: frame, configuration: configuration)
        #if DEVELOPMENT
            AltoWebView.aliveWebViewsCount += 1
        #endif
        allowsMagnification = true

        customUserAgent =
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    deinit {
        #if DEVELOPMENT
            AltoWebView.aliveWebViewsCount -= 1
        #endif
    }
}

extension WKWebView {
    /// WKWebView's `configuration` is marked with @NSCopying.
    /// So everytime you try to access it, it creates a copy of it, which is most likely not what we want.
    var configurationWithoutMakingCopy: WKWebViewConfiguration {
        (self as? AltoWebView)?.currentConfiguration ?? configuration
    }
}
