import SwiftUI

// MARK: - FavoriteView

struct FavoriteView: View {
    let model: TabViewModel
    @State private var isHovered = false

    var body: some View {
        HStack {
            model.tabIcon
                .resizable()
                .scaledToFit()
        }
        .padding(4)
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .draggable(model.tab) {
            Rectangle()
                .fill(.red)
        }
        .addTapGestures(
            singleTap: model.handleSingleClick,
            doubleTap: {}
        )
        .background(
            Rectangle()
                .fill(.white.opacity(0.2))
                .cornerRadius(5)
        )
        .onHover { _ in }
    }
}

// MARK: - AltoFavoriteView

struct AltoFavoriteView: View {
    let model: TabViewModel

    private var isSelected: Bool {
        model.state.currentSpace?.currentTab?.id == model.tab.id || model.isHovered
    }

    var body: some View {
        HStack {
            faviconImage(model: model)
        }
        .padding(4)
        .frame(width: 150)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(isSelected ? 0.4 : 0))
        )
        .contentShape(Rectangle())
        .addTapGestures(
            singleTap: model.handleSingleClick,
            doubleTap: model.handleDoubleClick
        )
        .draggable(model.tab) {
            AltoTabViewDragged(model: model)
        }
    }
}

// MARK: - View Extensions

private extension View {
    func addTapGestures(singleTap: @escaping () -> (), doubleTap: @escaping () -> ()) -> some View {
        gesture(
            TapGesture(count: 2).onEnded(doubleTap)
        )
        .simultaneousGesture(
            TapGesture().onEnded(singleTap)
        )
    }
}
