//



import SwiftUI
import Observation

struct TopbarView: View {
    @Environment(\.browser) private var browser
    var window: Window
    
    var body: some View {
        HStack {
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
                window.state = .sidebar
            } label: {
                Text("toggle")
            }
        }
    }
}
