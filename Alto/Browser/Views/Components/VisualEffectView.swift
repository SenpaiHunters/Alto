import AppKit
import SwiftUI

// MARK: - VisualEffectView

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let state: NSVisualEffectView.State

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.state = state
        view.blendingMode = .behindWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.state = state
    }
}
