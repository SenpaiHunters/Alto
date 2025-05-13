//
//  WindowView.swift
//  Alto
//
//  Created by Henson Liga on 5/10/25.
//
import SwiftUI


/// This is a temporary window view for testing
struct WindowView: View {
    var window: Window /// takes window class for handling the view
    
    var body: some View {
        
        
        VStack {
            Text(window.id.uuidString)
            Text(window.title)
            Text(window.manager.id.uuidString)
            
            /// Temporary button to test window system
            Button {
                window.manager.newWindow()
                //openWindow(id: "browser")
            } label: {
                Text("New Window")
            }
            Button {
                print(window.manager.favorites)
                //openWindow(id: "browser")
            } label: {
                Text("Print Tabs")
            }
            /// Temporary drag and drop view for testing
            DragAndDropView()
        }
    }
}
