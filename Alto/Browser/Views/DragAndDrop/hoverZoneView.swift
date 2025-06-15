//
import SwiftUI
import AppKit

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


// This code is crap we need to fix it
struct hoverZoneView: View {
    var model: HoverZoneViewModel
    
    var body: some View {
        if model.placement != .end {
            
            ZStack {
                if model.placement == .central {
                    Rectangle()
                        .fill(.blue.opacity(0))
                        .frame(width: model.width)
                        .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                            return model.onDrop(droppedTabs: droppedTabs, location: location)
                        } isTargeted: { targeted in
                            model.handleTargeted(targeted)
                        }
                    
                    
                    neadleView(isActive: model.isTargeted)
                }
                
                if model.placement == .start {
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
                }
            }
            .frame(width: 0)
            .zIndex(13)
        }
        if model.placement == .end {
            ZStack {
                HStack {
                    neadleView(isActive: model.isTargeted)
                        .offset(CGSize(width: 20, height: 0))
                    
                    Spacer()
                }
                
                Rectangle()
                    .fill(.blue.opacity(0))
            }
            
            .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                return model.onDrop(droppedTabs: droppedTabs, location: location)
            } isTargeted: { targeted in
                model.handleTargeted(targeted)
            }
            .offset(CGSize(width: -20, height: 0))
            .zIndex(13)
        }
    }
}
