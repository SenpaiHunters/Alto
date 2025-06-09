import SwiftUI

struct TopBarRigtButtonsView: View {
    @Environment(AltoState.self) private var altoState
    
    var body: some View {
        HStack {
            AltoButton(action: {altoState.browserTabsManager.createNewTab()}, icon: "plus")
        }
        .padding(.leading, 60) // Ensures topbar doesnt feel cramped with buttons and tabs
    }
}
