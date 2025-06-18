import OpenADK
import SwiftUI

struct TopBarRigtButtonsView: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        HStack {
            AltoButton(action: {
                if let tabManager = altoState.tabManager as? TabsManager {
                    tabManager.createNewTab(location: "unpinned")
                }
            }, icon: "plus", active: true)

            // AltoButton(action: {altoState.toggleTopbar()}, icon: "rectangle")
        }
        .padding(.leading, 40)
        .keyboardShortcut(Shortcuts.newTab) // Ensures topbar doesnt feel cramped with buttons and tabs
    }
}
