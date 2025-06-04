//

import SwiftUI

struct WindowBackgroundView: View {
    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, state: .active)
            Rectangle()
                .fill(.red)
                    .opacity(0.2)
        }
    }
}
