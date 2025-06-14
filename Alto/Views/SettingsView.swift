//
import SwiftUI


struct SettingsView: View {
    @Bindable var preferences = PreferencesManager.shared
    
    var body: some View {
        HStack {
            Text("\(PreferencesManager.shared.searchEngine)")
            Button {
                if  PreferencesManager.shared.storedColorScheme == "light" {
                    PreferencesManager.shared.storedColorScheme = "dark"
                } else {
                    PreferencesManager.shared.storedColorScheme = "light"
                }
            } label: {
                Text("swap theme")
            }
            
            Picker("Search Engine", selection: $preferences.searchEngine) {
                Text("Brave").tag(SearchEngines.brave)
                Text("duckduckgo").tag(SearchEngines.duckduckgo)
                Text("google").tag(SearchEngines.google)
            }
            
        }
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
    }
}

