//
//  AltoApp.swift
//  Alto
//
//  Created by Henson Liga on 5/9/25.
//

import SwiftUI

@main
struct AltoApp: App {
    var browser: Browser = Browser()
    
    var body: some Scene {
        WindowGroup {
            /// If at least 1 window exist it will use the first one for our starting window
            /// This is so we can manage the starting window with the browser class
            if let window = browser.windows.first {
                WindowView(window: window)
            }
        }
        .environment(\.browser, browser)
        
    }
}
