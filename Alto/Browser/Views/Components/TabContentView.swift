//
//  TabContentView.swift
//  Alto
//
//  Created by Kami on 26/06/2025.
//

import OpenADK
import SwiftUI
import WebKit

/// A wrapper view that displays tab content with optional blocking popup overlay
struct TabContentView: View {
    let webPage: ADKWebPage
    @ObservedObject private var blockingManager = ABBlockingManager.shared

    var body: some View {
        ZStack {
            // Main web content
            AnyView(webPage.returnView())

            // Blocking popup overlay (if active)
            if let webView = webPage.webView as? WKWebView {
                let activePopup = blockingManager.getActivePopup(for: webView)

                if let popupState = activePopup {
                    ContentBlockedView(
                        blockedURL: popupState.blockedURL,
                        blockerInfo: popupState.blockerInfo,
                        onContinueOnce: popupState.getContinueOnceAction(),
                        onWhitelistPermanently: popupState.getWhitelistAction(),
                        onCancel: popupState.getCancelAction()
                    )
                    .zIndex(1000) // Ensure popup appears on top
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.easeInOut(duration: 0.3), value: popupState.isVisible)
                    .onAppear {
                        print("🎭 ContentBlockedView appeared for URL: \(popupState.blockedURL)")
                    }
                    .onDisappear {
                        print("🎭 ContentBlockedView disappeared for URL: \(popupState.blockedURL)")
                    }
                }
            }
        }
        .onAppear {
            print("🎭 TabContentView appeared for: \(webPage.title)")
        }
    }
}
