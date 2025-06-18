import SwiftUI

struct WindowBackgroundView: View {
    @GestureState var isDraggingWindow = false

    var dragWindow: some Gesture {
        WindowDragGesture()
            .updating($isDraggingWindow) { _, state, _ in
                state = true
            }
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, state: .active)
            Rectangle()
                .fill(.white)
                .opacity(0.1)
        }
        .gesture(dragWindow)
    }
}
