import OpenADK
import SwiftUI

struct BrowserView<State: StateProtocol>: View where State == AltoState {
    var state: State

    var body: some View {
        ZStack {
            WindowBackgroundView()
            BrowserContentView()
            CommandPaletteView()
        }
        .environment(state)
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
        .ignoresSafeArea()
    }
}
