
import SwiftUI


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
        self.isMovableByWindowBackground = false
        self.isMovable = false
        if !showWinowButtons {
            self.standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
            self.standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
            self.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        }
        
        let info = WindowInfo()
        
        
        let mainView = BrowserView()
            .environment(info)
            .environment(self.state)
            .ignoresSafeArea()
        
        let hostingView = NSHostingView(rootView: mainView)
        
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        self.hostingView = hostingView
        
        contentView = hostingView
    }
}

