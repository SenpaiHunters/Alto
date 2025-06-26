import OpenADK
import SwiftUI

struct TopBarRigtButtonsView: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        HStack {
            // Download button
            DownloadButtonView()
                .frame(height: 30)
                .fixedSize()

            AltoButton(action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            }, icon: "plus", active: true)

            AltoButton(action: {
                AltoData.shared.spaceManager.newSpace(name: "asdf")
            }, icon: "rectangle.2.swap", active: true)

            // AltoButton(action: {altoState.toggleTopbar()}, icon: "rectangle")
        }
        .padding(.leading, 40)
        .keyboardShortcut(Shortcuts.newTab) // Ensures topbar doesnt feel cramped with buttons and tabs
    }
}
