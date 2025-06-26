//
import SwiftUI

struct closeButton: View {
    var model: TabViewModel

    var body: some View {
        Button(action: { model.handleClose(); print("hit") }) {
            model.closeIcon
        }
        .containerShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        .aspectRatio(1 / 1, contentMode: .fill)
    }
}
