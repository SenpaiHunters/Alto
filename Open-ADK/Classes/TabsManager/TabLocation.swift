
@Observable
class TabLocation {
    var id = UUID()
    var tabs: [TabRepresentation] = []
    
    func appendTabRep(_ tabRep: TabRepresentation) {
        self.tabs.append(tabRep)
        let tab = Alto.shared.getTab(id: tabRep.id)
        tab?.location = self
    }
    
    func removeTab(id: UUID) {
        let tabss = tabs.filter({ $0.id == id })
        
        print("removed tab:", tabss)
        tabs.removeAll(where: { $0.id == id })
        print("removed tab")
    }
}
