import OpenADK
import SwiftUI

// MARK: - FavoriteDropZoneView

struct FavoriteDropZoneView: View {
    let model: FavoriteDropZoneViewModel

    var body: some View {
        HStack {
            leadingDropZone
            mainContent
        }
    }

    private var leadingDropZone: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 0)
            .background(
                Rectangle()
                    .fill(.clear)
                    .frame(width: 30)
                    .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                        model.onDrop(droppedTabs: droppedTabs, location: location)
                    } isTargeted: { isTargeted in
                        model.handleTargeted(isTargeted)
                    }
            )
            .zIndex(12)
    }

    private var mainContent: some View {
        Group {
            if model.showEmptyDropIndicator {
                emptyFavoritesView
            } else if !model.isEmpty {
                favoriteTabsContent
            }
        }
    }

    private var emptyFavoritesView: some View {
        EmptyFavoritesView()
            .dropDestination(for: TabRepresentation.self) { droppedTabs, location in
                model.onDrop(droppedTabs: droppedTabs, location: location)
            } isTargeted: { isTargeted in
                model.handleTargeted(isTargeted)
            }
    }

    private var favoriteTabsContent: some View {
        Group {
            hoverZone(placement: .start)

            ForEach(Array(model.displayedTabs.enumerated()), id: \.element.id) { index, tabItem in
                AltoTabView(model: TabViewModel(state: model.state, draggingViewModel: model, tab: tabItem))
                hoverZone(for: index)
            }

            Spacer()
        }
    }

    private func hoverZone(for index: Int? = nil, placement: HoverZoneViewModel.ZonePlacement = .central) -> some View {
        Group {
            if let tabLocation = model.tabLocation as? TabLocation {
                if let index {
                    HoverZoneView(model: HoverZoneViewModel(
                        state: model.state,
                        tabLocation: tabLocation,
                        index: index
                    ))
                } else {
                    HoverZoneView(model: HoverZoneViewModel(
                        state: model.state,
                        tabLocation: tabLocation,
                        placement: placement
                    ))
                }
            }
        }
    }
}

// MARK: - EmptyFavoritesView

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
