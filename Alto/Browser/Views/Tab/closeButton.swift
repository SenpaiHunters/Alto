//
import SwiftUI

struct closeButton: View {
    var model: TabViewModel

    var body: some View {
        if model.isHovered {
            Button(action: { model.handleClose() }) {
                model.closeIcon
            }
            .containerShape(Rectangle())
            .buttonStyle(PlainButtonStyle())
            .aspectRatio(1 / 1, contentMode: .fill)
        }
    }
}
