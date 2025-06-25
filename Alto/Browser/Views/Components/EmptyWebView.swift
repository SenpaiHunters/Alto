
import SwiftUI

// MARK: - EmptyWebView

struct EmptyWebView: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, state: .active)
                .cornerRadius(10)

            Image("Logo")
                .opacity(0.5)
                .blendMode(.softLight)
                .scaleEffect(1.3)
        }
    }
}
