import OpenADK
import SwiftUI

// MARK: - BrowserContentView

struct BrowserContentView: View {
    @Environment(AltoState.self) private var altoState
    @Bindable var preferences: PreferencesManager = .shared
    @Namespace private var animation

    var data: AltoData {
        AltoData.shared
    }

    var body: some View {
        HStack(spacing: 5) {
            if altoState.sidebar, !altoState.sidebarIsRight {
                sidebar
            }
            VStack(spacing: 5) {
                if !altoState.sidebar {
                    topbar
                        .zIndex(1) // This ensures the spaces and url popups apear over the web content
                }
                content
            }

            if altoState.sidebar, altoState.sidebarIsRight {
                sidebar
            }
        }
        .padding(5)
    }

    @ViewBuilder
    private var topbar: some View {
        HStack(spacing: 2) {
            NavigationButtons

            tabsList
            Spacer()

            AltoButton(action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            }, icon: "plus", active: true)

            AltoButton(action: {
                AltoData.shared.spaceManager.newSpace(name: "asdf")
            }, icon: "rectangle.2.swap", active: true)
        }
        .frame(height: 30)
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack {
            HStack(spacing: 2) {
                NavigationButtons
            }
            .frame(height: 30)

            Button {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("New Tab")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(5)

            tabsList

            Spacer()
        }
        .frame(width: 250)
    }

    @ViewBuilder
    private var content: some View {
        let currentContent = altoState.currentContent

        if let currentContent {
            ForEach(Array(currentContent.enumerated()), id: \.element.id) { _, content in
                AnyView(content.returnView())
                    .cornerRadius(10)
                    .shadow(radius: 4)
            }
        } else {
            EmptyWebView()
        }
    }

    @ViewBuilder
    private var NavigationButtons: some View {
        if !altoState.sidebarIsRight || !altoState.sidebar {
            MacButtonsView()
                .padding(.leading, 6)
                .frame(width: 70)
        }

        AltoButton(
            action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.sidebar.toggle()
                }
            },
            icon: "sidebar.left",
            active: AltoData.shared.spaceManager.currentSpace?.currentTab?.content[0].canGoBack ?? false
        )
        .frame(height: 30)
        .fixedSize()
        .matchedGeometryEffect(id: "sidebar.left", in: animation)

        if altoState.sidebar {
            Spacer()
        }

        if !altoState.sidebar {
            SpacePickerView(model: SpacePickerViewModel(state: altoState))
        }

        AltoButton(
            action: {
                AltoData.shared.spaceManager.currentSpace?.currentTab?.content[0].goBack()
            },
            icon: "arrow.left",
            active: AltoData.shared.spaceManager.currentSpace?.currentTab?.content[0].canGoBack ?? false
        )
        .frame(height: 30)
        .fixedSize()
        .matchedGeometryEffect(id: "arrow.left", in: animation)

        AltoButton(
            action: {
                AltoData.shared.spaceManager.currentSpace?.currentTab?.content[0].goForward()
            },
            icon: "arrow.right",
            active: AltoData.shared.spaceManager.currentSpace?.currentTab?.content[0].canGoForward ?? false
        )
        .frame(height: 30)
        .fixedSize()
        .matchedGeometryEffect(id: "arrow.right", in: animation)

        AltoButton(
            action: {},
            icon: "arrow.clockwise",
            active: AltoData.shared.spaceManager.currentSpace?.currentTab?.content[0].canGoForward ?? false
        )
        .frame(height: 30)
        .fixedSize()
        .matchedGeometryEffect(id: "arrow.clockwise", in: animation)
    }

    @ViewBuilder
    private var tabsList: some View {
        let location = altoState.tabManager.getLocation("unpinned")!
        ForEach(location.tabs, id: \.id) { tab in
            AltoTabView(model: TabViewModel(
                state: altoState,
                draggingViewModel: DropZoneViewModel(
                    state: altoState,
                    tabLocation: altoState.tabManager.getLocation("unpinned")!
                ),
                tab: tab
            ))
            .frame(maxWidth: altoState.sidebar ? .infinity : 150)
            .frame(height: altoState.sidebar ? 30 : 30)
            .matchedGeometryEffect(id: tab, in: animation)
            
            hoverZoneView(model: HoverZoneViewModel(state: altoState, tabLocation: location, index: tab.index))
        }
    }
}
