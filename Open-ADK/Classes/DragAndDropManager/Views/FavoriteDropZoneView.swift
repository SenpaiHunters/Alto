//



import SwiftUI

struct FavoriteDropZoneView: View {
    var model: FavoriteDropZoneViewModel
    
    var body: some View {
        HStack {
            ZStack {
                Rectangle()
                    .fill(.red.opacity(0))
                    .frame(width: 30) 
                    .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                        model.onDrop(droppedTabs: droppedTabs, location: location) /// this will calculate the closses insertion point
                    } isTargeted: { isTargeted in
                        model.handleTargeted(isTargeted)
                    }
            }
            .frame(width: 0)
            .zIndex(12)
            
            if !model.showEmptyDropIndicator {
                if !model.isEmpty {
                    hoverZoneView(model: HoverZoneViewModel(state: model.state, tabLocation: model.tabLocation, isFirst: true))
                    
                    ForEach(Array(model.displayedTabs.enumerated()), id: \.element.id) { index, tabItem in
                        AltoTabView(model: TabViewModel(state: model.state, draggingViewModel: model, tab: tabItem))
                        hoverZoneView(model: HoverZoneViewModel(state: model.state, tabLocation: model.tabLocation, index: index))
                    }
                    Spacer()
                }
            } else {
                EmptyFavoritesView()
                    .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                        model.onDrop(droppedTabs: droppedTabs, location: location) /// this will calculate the closses insertion point
                    } isTargeted: { isTargeted in
                        model.handleTargeted(isTargeted)
                    }
            }
        }
    }
}


struct EmptyFavoritesView: View {
    var body: some View {
        HStack {
            Image(systemName: "star.circle.fill")
                .resizable()
                .scaledToFit()
                .cornerRadius(5)
            
            Text("Add to Favorites")
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.4))
        )
        .zIndex(12)
    }
}

