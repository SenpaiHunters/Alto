//

@Observable
class FavoriteDropZoneViewModel: DropZoneViewModel {
    var showEmptyDropIndicator: Bool {
        isTargeted && isEmpty
    }

    override func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        isTargeted = targeted
    }
}
