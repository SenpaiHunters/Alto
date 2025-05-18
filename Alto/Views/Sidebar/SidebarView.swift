//



import SwiftUI
import Observation

struct SidebarView: View {
    @Environment(\.browser) private var browser
    var window: Window
    
    var body: some View {
        VStack {
            /// The drop areas for the tabs
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.favoritesId))
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.getSpace().pinnedId))
            DragAndDropView(DragAndDropViewModel(browser: browser, window: window, containerId: browser.getSpace().unpinnedId))
            Spacer()
            
            Button {
                browser.newTab()
            } label: {
                Text("New Tab")
            }
            Button {
                window.state = .topbar
            } label: {
                Text("toggle")
            }
        }
    }
}
