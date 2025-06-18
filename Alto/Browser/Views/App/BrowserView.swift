//

import OpenADK
import SwiftUI

struct BrowserView: View {
    var genaricState: any StateProtocol

    // If you can find a better solution please make a pr!
    var state: AltoState? {
        if let altoState = genaricState as? AltoState {
            return altoState
        }
        return nil
    }

    var body: some View {
        ZStack {
            WindowBackgroundView()
            BrowserContentView()
        }
        .environment(state)
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
        .ignoresSafeArea()
    }
}
