import OpenADK
import SwiftUI

// MARK: - AltoTopBar

struct AltoTopBar: View {
    var model: AltoTopBarViewModel
    
    var body: some View {
        HStack(spacing: 2) {
            MacButtonsView()
                .padding(.leading, 6)
                .frame(width: 70)

            SpacePickerView(model: SpacePickerViewModel(state: model.state))
                .fixedSize()

            FavoriteDropZoneView(model: FavoriteDropZoneViewModel(
                state: model.state,
                tabLocation: model.state.tabManager.tabLocations[0]
            ))
            .frame(height: 30)
            .fixedSize()
            
            if !model.state.tabManager.tabLocations[0].tabs.isEmpty {
                Divider().frame(width: 2)
            }

            
            TopBarRigtButtonsView()
                .frame(height: 30)
                .fixedSize()
        }
        .frame(height: 30)
        .zIndex(100_000)
    }
}

// MARK: - SpacePickerViewModel

@Observable
class SpacePickerViewModel {
    var state: AltoState
    var tabManager: AltoTabsManager? {
        state.tabManager as? AltoTabsManager
    }
    // Changed `spaces` to a computed property to ensure it's always up-to-date.
    var spaces: [Space] {
        AltoData.shared.spaceManager.spaces
    }

    var isDisplaying = false

    init(state: AltoState) {
        self.state = state
    }
}


// MARK: - SpacePickerView

struct SpacePickerView: View {
    var model: SpacePickerViewModel

    var body: some View {
        HStack {
            Text(model.tabManager?.currentSpace?.name ?? "Select Space")
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
                            .zIndex(1_000_000)

                }
            },
            alignment: .topLeading
        )
    }
}


// MARK: - PickerDropdownView

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
                            model.tabManager?.currentSpace = space
                            model.isDisplaying = false
                        } label: {
                            HStack {
                                Text(space.name)
                                    .foregroundColor(.primary)
                                Spacer()
                                // Add a checkmark to indicate the active space.
                                if space.id == model.tabManager?.currentSpace?.id {
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

        .zIndex(1_000_000)

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
