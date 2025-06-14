//
import SwiftUI


struct AltoTabViewDragged: View {
    var model: TabViewModel
    
    var body: some View {
        HStack {
            faviconImage(model: model)
            
            Text(model.tabTitle)
            Spacer()
        }
        .padding(4)
        .frame(width: 150)
        .allowsHitTesting(false)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.4))
        )
        .onAppear(
            perform: {
                model.state.draggedTab = model.tab
                model.isDragged = true
                model.state.browserTabsManager.currentSpace.currentTab = model.altoTab
            }
        )
        .onDisappear(
            perform: {
                model.isDragged = false
            }
        )
    }
}
