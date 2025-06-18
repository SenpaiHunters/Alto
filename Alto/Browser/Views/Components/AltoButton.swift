
import SwiftUI

struct AltoButton: View {
    @State var isHovered = false
    var action: () -> ()
    var icon: String
    var active: Bool

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered && active ? .gray.opacity(0.4) : .gray.opacity(0))
                Image(systemName: icon)
                    .opacity(active ? 1 : 0.3)
            }
            .animation(.bouncy, value: isHovered)
            .onHover { hovered in
                isHovered = hovered
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(PlainButtonStyle())
    }
}
