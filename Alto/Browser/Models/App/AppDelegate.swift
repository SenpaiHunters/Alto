import AppKit
import OpenADK
import WebKit

/// Handles major portions of tha app lifecycle
///
/// Because browsers need the ability to open many windows we need a managments system
/// We use a WindowManager class but this is needed to handling opening windows according to the app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager = Alto.shared.windowManager

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App Launched")

        // Initialize AdBlocker on app startup
        print("🛡️ Initializing AdBlocker...")
        Task {
            await ABManager.shared.initializeContentBlocking()
            print("✅ AdBlocker initialized successfully")
        }

        // Set up notification listener for new WebViews
        setupAdBlockNotificationListener()

        var windowConfig = DefaultWindowConfiguration()

        windowConfig.stateFactory = { AltoState() }

        windowConfig.setView { state in
            BrowserView(genaricState: state)
        }

        windowManager.configuration = windowConfig

        windowManager.createWindow(tabs: [])
    }

    /// Set up notification listener for AdBlock integration
    private func setupAdBlockNotificationListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AltoWebViewCreated"),
            object: nil,
            queue: .main
        ) { notification in
            guard let webView = notification.object as? WKWebView else {
                print("⚠️ AdBlock: Invalid WebView object in notification")
                return
            }

            print("🔌 AdBlock: Setting up blocking for new WebView")
            Task {
                await ABIntegration.shared.setupAdBlocking(for: webView)
                print("✅ AdBlock: Setup complete for WebView")
            }
        }

        print("👂 AdBlock: Notification listener registered")
    }
}
