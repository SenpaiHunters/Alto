//

import SwiftUI

struct faviconImage: View {
    var model: TabViewModel

    var body: some View {
        model.tabIcon
            .resizable()
            .scaledToFit()
            .cornerRadius(5)
    }
}
