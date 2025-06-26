//

import AppKit
import OpenADK
import SwiftUI

// MARK: - AltoWindow

/// A modified version of the NSWindow class
@Observable
public class AltoWindow: ADKWindow {
    // MARK: - Properties

    public var showWinowButtons = false

    public init(rootView: NSView, state: AltoState) {
        super.init(rootView: rootView, state: state, useDefaultProfile: false)
        print("but why?")
        /// Window Configurations
        toolbar?.isVisible = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        isReleasedWhenClosed = false
        isMovableByWindowBackground = false
        isMovable = false

        /// Removes the window buttons
        if !showWinowButtons {
            standardWindowButton(NSWindow.ButtonType.closeButton)?.isHidden = true
            standardWindowButton(NSWindow.ButtonType.zoomButton)?.isHidden = true
            standardWindowButton(NSWindow.ButtonType.miniaturizeButton)?.isHidden = true
        }
    }
}
