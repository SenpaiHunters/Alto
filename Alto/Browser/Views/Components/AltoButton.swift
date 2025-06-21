import SwiftUI

struct AltoButton: View {
    let action: () -> ()
    let icon: String
    let active: Bool
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.gray.opacity(isHovered && active ? 0.4 : 0))
                Image(systemName: icon)
                    .opacity(active ? 1 : 0.3)
            }
            .animation(.bouncy, value: isHovered)
            .onHover { isHovered = $0 }
        }
        .aspectRatio(1, contentMode: .fit)
        .buttonStyle(.plain)
    }
}
