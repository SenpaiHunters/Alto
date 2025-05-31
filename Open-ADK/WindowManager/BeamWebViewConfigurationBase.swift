//



class AltoWebViewConfigurationBase: WKWebViewConfiguration {
    static var allowsPictureInPicture: Bool {
        #if BEAM_WEBKIT_ENHANCEMENT_ENABLED
        return true
        #else
        return false
        #endif
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    /// Doing `registerAllMessageHandlers` in the convenience init fixes a bug in webkit
    /// where the `WKWebViewConfiguration` creates multiple references to the assigned WKMessageHandlers

    override init() {
        super.init()

        preferences.javaScriptCanOpenWindowsAutomatically = true
        preferences.isFraudulentWebsiteWarningEnabled = true
        preferences.setValue(true, forKey: "developerExtrasEnabled")
        defaultWebpagePreferences.preferredContentMode = .desktop
        defaultWebpagePreferences.allowsContentJavaScript = true
    }

}
