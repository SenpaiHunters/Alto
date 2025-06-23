import OpenADK
import SwiftUI

struct AltoTopBar: View {
    var model: AltoTopBarViewModel
    
    var body: some View {
        HStack(spacing: 2) {
            MacButtonsView()
                .padding(.leading, 6)
                .frame(width: 70)
            
            SpacePickerView(model: SpacePickerViewModel(state: model.state))
                .fixedSize()
            
            
            AltoButton(action: {
                model.state.currentSpace?.currentTab?.content[0].goBack()
            }, icon: "arrow.left", active: model.state.currentSpace?.currentTab?.content[0].canGoBack ?? false)
            .frame(height: 30)
            .fixedSize()
            .keyboardShortcut(Shortcuts.goBack)
            .keyboardShortcut(Shortcuts.goBackAlt)
            
            AltoButton(action: {
                model.state.currentSpace?.currentTab?.content[0].goForward()
            }, icon: "arrow.right", active: model.state.currentSpace?.currentTab?.content[0].canGoForward ?? false)
            .frame(height: 30)
            .fixedSize()
            .keyboardShortcut(Shortcuts.goForward)
            .keyboardShortcut(Shortcuts.goForwardAlt)
            
            FavoriteDropZoneView(model: FavoriteDropZoneViewModel(
                state: model.state,
                tabLocation: model.state.tabManager.globalLocations[0]
            ))
            .frame(height: 30)
            .fixedSize()
            
            if !model.state.tabManager.globalLocations[0].tabs.isEmpty {
                Divider().frame(width: 2)
            }
            
            // TODO: make a better system for getting tab locations
            if let tabLocation = model.state.currentSpace?.localLocations[1] {
                DropZoneView(model: DropZoneViewModel(
                    state: model.state,
                    tabLocation: tabLocation
                ))
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .layoutPriority(1)
            }
            
            TopBarRigtButtonsView()
                .frame(height: 30)
                .fixedSize()
        }
        .frame(height: 30)
        .zIndex(100000)
    }
}

@Observable
class SpacePickerViewModel {
    var state: GenaricState
    // Changed `spaces` to a computed property to ensure it's always up-to-date.
    var spaces: [Space] {
        Alto.shared.spaceManager.spaces
    }
    var isDisplaying: Bool = false
    
    init(state: GenaricState) {
        self.state = state
    }
}


struct SpacePickerView: View {
    var model: SpacePickerViewModel
    
    var body: some View {
        HStack {
            Text(model.state.currentSpace?.name ?? "Select Space")
            Image(systemName: "chevron.down")
        }
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Rectangle().fill(.gray.opacity(0.15)).cornerRadius(5))
        .onTapGesture {
            model.isDisplaying.toggle()
        }
        .overlay(
            Group {
                if model.isDisplaying {
                    PickerDropdownView(model: model, items: model.spaces)
                        // Offset the dropdown to appear below the button.
                        .offset(y: 35)
                        .zIndex(1000000)
                }
            },
            alignment: .topLeading
        )
    }
}

// TODO: Make this a general view for all drop downs
struct PickerDropdownView: View {
    var model: SpacePickerViewModel
    var items: [Space]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(items, id: \.id) { space in
                        Button {
                            model.state.currentSpace = space
                            model.isDisplaying = false
                        } label: {
                            HStack {
                                Text(space.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                // Add a checkmark to indicate the active space.
                                if space.id == model.state.currentSpace?.id {
                                    Image(systemName: "checkmark")
                                        .font(.headline.weight(.semibold))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        if space.id != items.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .zIndex(1000000)
        .padding(.vertical, 5)
        .frame(width: 240)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}
