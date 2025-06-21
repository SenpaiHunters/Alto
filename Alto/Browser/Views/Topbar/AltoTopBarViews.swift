import OpenADK
import SwiftUI

struct AltoTopBar: View {
    var model: AltoTopBarViewModel

    var body: some View {
        HStack(spacing: 2) {
            // MacButtonsViewNew()
            MacButtonsView()
                .padding(.leading, 6)
                .frame(width: 70)

            // TODO: add spaces dropdown
            AltoButton(action: {
                model.state.currentSpace?.currentTab?.content[0].goBack()
            }, icon: "arrow.left", active: model.state.currentSpace?.currentTab?.content[0].canGoBack ?? false)
                .frame(height: 30)
                .fixedSize()
                .keyboardShortcut(Shortcuts.Tab.goBack)
                .keyboardShortcut(Shortcuts.Tab.goBackAlt)

            AltoButton(action: {
                model.state.currentSpace?.currentTab?.content[0].goForward()
            }, icon: "arrow.right", active: model.state.currentSpace?.currentTab?.content[0].canGoForward ?? false)
                .frame(height: 30)
                .fixedSize()
                .keyboardShortcut(Shortcuts.Tab.goForward)
                .keyboardShortcut(Shortcuts.Tab.goForwardAlt)

            FavoriteDropZoneView(model: FavoriteDropZoneViewModel(
                state: model.state,
                tabLocation: model.state.tabManager.globalLocations[0]
            ))
            .frame(height: 30)
            .fixedSize()

            if !model.state.tabManager.globalLocations[0].tabs.isEmpty {
                Divider().frame(width: 2)
            }

            if let tabLocation = model.state.currentSpace?.localLocations[1] {
                DropZoneView(model: DropZoneViewModel(
                    state: model.state,
                    tabLocation: tabLocation
                ))
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }

            TopBarRigtButtonsView()
                .frame(height: 30)
                .fixedSize()
        }
        .frame(height: 30)
    }
}
