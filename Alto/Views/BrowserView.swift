//

import SwiftUI

struct BrowserView: View {
    var body: some View {
        ZStack {
            WindowBackgroundView()
            BrowserContentView()
        }
    }
}

#Preview {
    BrowserView()
}

