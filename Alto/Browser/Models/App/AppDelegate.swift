//

/// Handles major portions of tha app lifecycle
///
/// Because browsers need the ability to open many windows we need a managments system
/// We use a WindowManager class but this is needed to handling opening windows according to the app lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager = Alto.shared.windowManager

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App Launched")

        Alto.shared.windowManager.createWindow()
    }
}
