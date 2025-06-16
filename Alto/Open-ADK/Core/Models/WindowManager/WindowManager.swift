//

import SwiftUI

/// Manages window Creation
class WindowManager {
    
    var window: AltoWindow? { // We need to make our own Window type like AltoWindow
        (NSApplication.shared.keyWindow as? AltoWindow) ?? (NSApplication.shared.mainWindow as? AltoWindow)
    }
    var windows: [AltoWindow] = []
    
    // Private init as this is a singleton and only gets called once
    init() {
        
    }
    
    func createWindow() {
        let window = AltoWindow(
            contentRect: NSRect(x: 150, y: 150, width: 800, height: 600)
        )
        
        
        window.orderFront(nil)
    }
    
}

/// This will hold information about the window
@Observable
class WindowInfo {
    var id = UUID()
}

