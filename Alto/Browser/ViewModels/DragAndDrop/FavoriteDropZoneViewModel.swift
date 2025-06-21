import AppKit
import Observation
import OpenADK

@Observable
class FavoriteDropZoneViewModel: DropZoneViewModel {
    var showEmptyDropIndicator: Bool { isTargeted && isEmpty }
}
