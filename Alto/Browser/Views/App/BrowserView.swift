//

import OpenADK
import SwiftUI

struct BrowserView: View {
    @Environment(AltoState.self) private var altoState

    // If you can find a better solution please make a pr!

    var body: some View {
        ZStack {
            WindowBackgroundView()
            BrowserContentView()
            CommandPaletteView()
        }
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
        .ignoresSafeArea()
    }
}
