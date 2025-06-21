import OpenADK
import SwiftUI

// MARK: - TopBarRigtButtonsView

struct TopBarRigtButtonsView: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        HStack {
            AltoButton(action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            }, icon: "plus", active: true)

            // AltoButton(action: {altoState.toggleTopbar()}, icon: "rectangle")
        }
        .padding(.leading, 40) // Ensures topbar doesnt feel cramped with buttons and tabs
        .keyboardShortcut(Shortcuts.Tab.newTab)
    }
}
