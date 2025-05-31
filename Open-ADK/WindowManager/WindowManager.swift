//

import SwiftUI

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
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300)
        )
        
        window.orderFront(nil)
    }
    
}


@Observable
class WindowInfo {
    var id = UUID()
}


class AltoWindow: NSWindow {
    // Window Configuration Vars
    
    let state: AltoState
    let showWinowButtons = false
    private var hostingView: NSView?
    
    init(contentRect: NSRect, state: AltoState? = nil, title: String? = nil, isIncognito: Bool = false, minimumSize: CGSize? = nil) {
        self.state = state ?? AltoState()

        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                   backing: .buffered, defer: false)
        
        self.toolbar?.isVisible = false
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isReleasedWhenClosed = false
        
        if !showWinowButtons {
            self.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
            self.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
            self.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        }
        
        let info = WindowInfo()
        let mainView = dummyView()
            .environment(info)
            .environment(self.state)
        
        let hostingView = NSHostingView(rootView: mainView)

        hostingView.translatesAutoresizingMaskIntoConstraints = false

        self.hostingView = hostingView

        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .hudWindow
        contentView = hostingView
        
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        //self.contentView?.addSubview(hostingView)

        self.isMovableByWindowBackground = false
    }
    
}
