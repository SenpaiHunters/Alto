//



@Observable
class FavoriteDropZoneViewModel: DropZoneViewModel {
    
    var showEmptyDropIndicator: Bool {
        return (self.isTargeted && isEmpty)
    }
    
    
    
    override func handleTargeted(_ targeted: Bool) {
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        self.isTargeted = targeted
    }
}
