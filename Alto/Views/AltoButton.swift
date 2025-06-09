
import SwiftUI


struct AltoButton: View {
    @State var isHovered: Bool = false
    var action: () -> Void
    var icon: String
    
    var body: some View {
        Button(action:action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovered ? .gray.opacity(0.4) : .gray.opacity(0.3))
                Image(systemName: icon)
            }
            .animation(.bouncy, value: isHovered)
            .onHover { hovered in
                isHovered = hovered
            }
        }
        .frame(maxWidth: 50)
        .buttonStyle(PlainButtonStyle())
    }
}
