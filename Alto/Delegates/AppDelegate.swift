
import SwiftUI
import Foundation
import WebKit

class AppDelegate1: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        hideWindowIcons()
    }
    
    func applicationDidUpdate(_ notification: Notification) {
        hideWindowIcons()
    }
    
    func hideWindowIcons() {
        NSApp.mainWindow?.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
        NSApp.mainWindow?.standardWindowButton(NSWindow.ButtonType.closeButton)!.isHidden = true
        NSApp.mainWindow?.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isHidden = true
    }
}
