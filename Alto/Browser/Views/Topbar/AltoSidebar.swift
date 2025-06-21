import SwiftUI

// MARK: - SidebarTabView

struct SidebarTabView: View {
    var model: DropZoneViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 2) {
                // Favorites section
                if !model.state.tabManager.globalLocations[0].tabs.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Favorites")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)

                        ForEach(model.state.tabManager.globalLocations[0].tabs, id: \.id) { tab in
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

                // Extensions section
                if !model.state.loadedExtensions.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Extensions")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)

                        ForEach(
                            model.state.loadedExtensions.sorted(by: { $0.manifest.name < $1.manifest.name }),
                            id: \.id
                        ) { webExtension in
                            SidebarExtensionItem(
                                webExtension: webExtension,
                                state: model.state
                            )
                        }
                    }
                    .padding(.bottom, 8)

                    Divider()
                        .padding(.horizontal, 8)
                }

                // Regular tabs section
                VStack(alignment: .leading, spacing: 2) {
                    if !model.state.tabManager.globalLocations[0].tabs.isEmpty {
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

// MARK: - SidebarExtensionItem

struct SidebarExtensionItem: View {
    let webExtension: WebExtension
    let state: AltoState
    @State private var isHovered = false
    @State private var extensionWindowManager = ExtensionWindowManager.shared

    var body: some View {
        HStack {
            // Extension icon
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.blue.gradient)
                .frame(width: 16, height: 16)
                .overlay(
                    Image(systemName: "puzzlepiece.extension")
                        .foregroundColor(.white)
                        .font(.system(size: 8, weight: .medium))
                )

            Text(webExtension.manifest.name)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.system(size: 12))

            Spacer()

            // Extension status indicator
            Circle()
                .fill(state.isExtensionsEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding(4)
        .frame(height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? .gray.opacity(0.4) : .gray.opacity(0))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            extensionWindowManager.openExtensionWindow(webExtension)
        }
        .onHover { hovered in
            isHovered = hovered
        }
        .help("Click to open \(webExtension.manifest.name)")
        .padding(.horizontal, 4)
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
            RoundedRectangle(cornerRadius: 8)
                .fill((model.state.currentSpace?.currentTab?.id == model.tab.id || model.isHovered) ?
                    .gray.opacity(0.4) : .gray.opacity(0)
                )
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
