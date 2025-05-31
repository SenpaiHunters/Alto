//

import SwiftUI


@main
struct AltoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        
    }
    
    var body: some Scene {
        Settings {} // No default window
    }
}


class AppDelegate: NSObject, NSApplicationDelegate {
    var windowManager = AltoData.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App Launched")
        AltoData.shared.windowManager.createWindow()
    }
}
