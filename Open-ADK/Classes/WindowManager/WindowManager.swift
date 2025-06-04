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
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300)
        )
        
        window.orderFront(nil)
    }
    
}

/// This will hold information about the window
@Observable
class WindowInfo {
    var id = UUID()
}

/// An Window class with extra features
///
/// This was the first code I wrote for the project is a slightly modified version of Beams implimentation:
/// https://github.com/beamlegacy/beam/blob/3fa234d6ad509c2755c16fb3fd240e9142eaa8bb/Beam/Classes/Views/BeamWindow.swift#L13
class AltoWindow: NSWindow {
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

        contentView = hostingView
        
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden

        self.isMovableByWindowBackground = false
    }
    
}
