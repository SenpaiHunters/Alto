//
import SwiftUI


struct closeButton: View {
    var model: TabViewModel
    
    var body: some View {
        if model.isDragged {
            Button(action:{model.handleClose()}) {
                model.closeIcon
            }
            .buttonStyle(PlainButtonStyle())
            .aspectRatio(1/1, contentMode: .fit)
        }
    }
}
