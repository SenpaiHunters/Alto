//
import SwiftUI

// What is needed:


struct SettingsView: View {
    @Bindable var preferences = PreferencesManager.shared
    
    var body: some View {
        Form {
            
            Button {
                print(preferences.searchEngine)
            } label: {
                Text("search engine current")
            }
            Picker("Theme", selection: $preferences.storedColorScheme) {
                Text("Light").tag("light")
                Text("Dark").tag("dark")
                Text("System").tag("") // Needs Fix
                    .pickerStyle(.menu)
            }
            Picker("Search Engine", selection: $preferences.storedSearchEngine) {
                Text("Brave").tag("brave")
                Text("Duckduckgo").tag("duckduckgo")
                Text("Google").tag("google")
            }
            .pickerStyle(.menu)
        }
        .padding(10)
        .frame(maxWidth: 300) // Added width constraint
        .preferredColorScheme(PreferencesManager.shared.colorScheme)
    }
}

#Preview {
    SettingsView()
}
