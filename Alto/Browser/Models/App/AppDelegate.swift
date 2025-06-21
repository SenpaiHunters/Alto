import AppKit
import OpenADK

/// Handles major portions of tha app lifecycle
///
/// Because browsers need the ability to open many windows we need a managments system
/// We use a WindowManager class but this is needed to handling opening windows according to the app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager = Alto.shared.windowManager

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App Launched")

        var windowConfig = DefaultWindowConfiguration()

        windowConfig.stateFactory = { AltoState() }

        windowConfig.setView { state in
            // Cast the state to AltoState since we know it's created by our factory
            guard let altoState = state as? AltoState else {
                fatalError("Expected AltoState from factory")
            }
            return BrowserView(state: altoState)
        }

        windowManager.configuration = windowConfig

        windowManager.createWindow(tabs: [])
    }
}
