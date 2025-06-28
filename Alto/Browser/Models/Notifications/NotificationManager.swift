//
//  NotificationManager.swift
//  Alto
//
//  Created by Kami on 27/06/2025.
//

import Foundation

/// Notification names for content blocking events
extension Notification.Name {
    // Content blocking events
    static let contentWasBlocked = Notification.Name("ContentWasBlocked")

    // Extension events
    static let extensionInstalled = Notification.Name("ExtensionInstalled")
    static let extensionRemoved = Notification.Name("ExtensionRemoved")
    static let extensionEnabled = Notification.Name("ExtensionEnabled")
    static let extensionDisabled = Notification.Name("ExtensionDisabled")
    static let webViewDidFinishNavigation = Notification.Name("WebViewDidFinishNavigation")
}
