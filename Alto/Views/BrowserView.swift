//

import SwiftUI

struct BrowserView: View {
    
    var body: some View {
        ZStack {
            WindowBackgroundView()
            BrowserContentView()
        }
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
    }
}
