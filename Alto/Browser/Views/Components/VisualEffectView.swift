//

import AppKit
import SwiftUI

// Creates a representable so window can use appkit exclusive Materials
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var state: NSVisualEffectView.State
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.state = .active
        view.blendingMode = .behindWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.state = state
    }
}
