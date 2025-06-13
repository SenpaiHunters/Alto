//
import SwiftUI
import AppKit

struct hoverZoneView: View {
    var model: HoverZoneViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.blue.opacity(0))
                .offset(model.offset)
                .frame(width: model.width)
                .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                    return model.onDrop(droppedTabs: droppedTabs, location: location)
                } isTargeted: { targeted in
                    model.handleTargeted(targeted)
                }
            
            neadleView(isActive: model.isTargeted)
            
            // Text("\(model.index)")
        }
        .frame(width: 0)
        .zIndex(13)
    }
}


struct neadleView: View {
    var isActive: Bool
    
    var body: some View {
        VStack (spacing: 0) {
            if isActive {
                
                Circle()
                    .fill(.clear)
                    .stroke(.blue, lineWidth: 2)
                    .frame(width: 8, height: 8)
                
                Rectangle()
                    .fill(.blue)
                    .frame(width: 2)
            }
        }
    }
}
