//
import SwiftUI

@Observable
class PreferencesManager {
    var shared: PreferencesManager = PreferencesManager()
    
    var altoAppearance: AltoAppearance = .dark
    
    private init() {
        // this would normaly pull settings from storage
        
        UserDefaults.standard.set(altoAppearance.rawValue, forKey: "TEST")
    }
}


enum AltoAppearance: Int {
    case dark
    case light
    case system
}
