import SwiftUI

// MARK: - SidebarTabView

struct SidebarTabView: View {
    var model: DropZoneViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                // Favorites section
                if !model.state.tabManager.tabLocations[0].tabs.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Favorites")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)

                        ForEach(model.state.tabManager.tabLocations[0].tabs, id: \.id) { tab in
                            SidebarTabItem(
                                model: TabViewModel(
                                    state: model.state,
                                    draggingViewModel: model,
                                    tab: tab
                                ),
                                isFavorite: true
                            )
                        }
                    }
                    .padding(.bottom, 8)

                    Divider()
                        .padding(.horizontal, 8)
                }

                // Regular tabs section
                VStack(alignment: .leading, spacing: 2) {
                    if !model.state.tabManager.tabLocations[0].tabs.isEmpty {
                        Text("Tabs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                    }

                    ForEach(Array(model.displayedTabs.enumerated()), id: \.element.id) { _, tabItem in
                        SidebarTabItem(
                            model: TabViewModel(
                                state: model.state,
                                draggingViewModel: model,
                                tab: tabItem
                            ),
                            isFavorite: false
                        )
                    }
                }

                Spacer()
            }
        }
        .frame(width: 200)
        .animation(.snappy(duration: 0.15), value: model.displayedTabs)
    }
}

// MARK: - SidebarTabItem

struct SidebarTabItem: View {
    var model: TabViewModel
    var isFavorite: Bool

    var body: some View {
        HStack {
            faviconImage(model: model)

            Text(model.tabTitle)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            closeButton(model: model)
        }
        .padding(4)
        .frame(height: 30) // Match the height of horizontal tabs
        .background(
        )
        .contentShape(Rectangle())
        .gesture(
            TapGesture(count: 2).onEnded {
                model.handleDoubleClick()
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                model.handleSingleClick()
            }
        )
        .onHover { hovered in
            model.isHovered = hovered
        }
        .draggable(model.tabRepresentation) {
            AltoTabViewDragged(model: model)
        }
        .padding(.horizontal, 4) // Add some margin from sidebar edges
    }
}
