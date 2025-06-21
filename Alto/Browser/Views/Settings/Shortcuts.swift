//
//  Shortcuts.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import SwiftUI

// MARK: - Shortcuts

enum Shortcuts {
    // MARK: - Tab Management

    enum Tab {
        static let new = KeyboardShortcut("t", modifiers: [.command])
        static let openCommandPalette = KeyboardShortcut("l", modifiers: [.command])
        static let close = KeyboardShortcut("w", modifiers: [.command])
        static let closeWindow = KeyboardShortcut("w", modifiers: [.command, .shift])
        static let reopen = KeyboardShortcut("t", modifiers: [.command, .shift])
        static let duplicate = KeyboardShortcut("d", modifiers: [.command])
        static let newTab = KeyboardShortcut("t", modifiers: [.command])
        static let goBack = KeyboardShortcut(.leftArrow, modifiers: [.command])
        static let goBackAlt = KeyboardShortcut("[", modifiers: [.command])
        static let goForward = KeyboardShortcut(.rightArrow, modifiers: [.command])
        static let goForwardAlt = KeyboardShortcut("]", modifiers: [.command])

        // Tab Navigation
        static let nextTab = KeyboardShortcut(.tab, modifiers: [.command, .option])
        static let previousTab = KeyboardShortcut(.tab, modifiers: [.command, .option, .shift])
        static let selectTab1 = KeyboardShortcut("1", modifiers: [.command])
        static let selectTab2 = KeyboardShortcut("2", modifiers: [.command])
        static let selectTab3 = KeyboardShortcut("3", modifiers: [.command])
        static let selectTab4 = KeyboardShortcut("4", modifiers: [.command])
        static let selectTab5 = KeyboardShortcut("5", modifiers: [.command])
        static let selectTab6 = KeyboardShortcut("6", modifiers: [.command])
        static let selectTab7 = KeyboardShortcut("7", modifiers: [.command])
        static let selectTab8 = KeyboardShortcut("8", modifiers: [.command])
        static let selectTab9 = KeyboardShortcut("9", modifiers: [.command])
        static let selectLastTab = KeyboardShortcut("9", modifiers: [.command, .shift])
    }

    // MARK: - Navigation

    enum Navigation {
        static let goBack = KeyboardShortcut(.leftArrow, modifiers: [.command])
        static let goBackAlt = KeyboardShortcut("[", modifiers: [.command])
        static let goForward = KeyboardShortcut(.rightArrow, modifiers: [.command])
        static let goForwardAlt = KeyboardShortcut("]", modifiers: [.command])
        static let reload = KeyboardShortcut("r", modifiers: [.command])
        static let hardReload = KeyboardShortcut("r", modifiers: [.command, .shift])
        static let home = KeyboardShortcut(.home, modifiers: [.command])
        static let stop = KeyboardShortcut(.escape, modifiers: [])
    }

    // MARK: - Address Bar & Search

    enum AddressBar {
        static let focus = KeyboardShortcut("l", modifiers: [.command])
        static let focusAlt = KeyboardShortcut("d", modifiers: [.command])
        static let search = KeyboardShortcut("k", modifiers: [.command])
        static let searchInPage = KeyboardShortcut("f", modifiers: [.command])
        static let findNext = KeyboardShortcut("g", modifiers: [.command])
        static let findPrevious = KeyboardShortcut("g", modifiers: [.command, .shift])
    }

    // MARK: - Bookmarks & History

    enum Bookmarks {
        static let addBookmark = KeyboardShortcut("d", modifiers: [.command])
        static let showBookmarks = KeyboardShortcut("b", modifiers: [.command, .option])
        static let showHistory = KeyboardShortcut("y", modifiers: [.command])
        static let clearHistory = KeyboardShortcut("y", modifiers: [.command, .shift])
    }

    // MARK: - View & Display

    enum View {
        static let toggleFullScreen = KeyboardShortcut("f", modifiers: [.command, .control])
        static let actualSize = KeyboardShortcut("0", modifiers: [.command])
        static let zoomIn = KeyboardShortcut("=", modifiers: [.command])
        static let zoomOut = KeyboardShortcut("-", modifiers: [.command])
        static let toggleSidebar = KeyboardShortcut("s", modifiers: [.command, .option])
        static let toggleDevTools = KeyboardShortcut("i", modifiers: [.command, .option])
        static let viewSource = KeyboardShortcut("u", modifiers: [.command, .option])
    }

    // MARK: - Window Management

    enum Window {
        static let newWindow = KeyboardShortcut("n", modifiers: [.command])
        static let newPrivateWindow = KeyboardShortcut("n", modifiers: [.command, .shift])
        static let closeWindow = KeyboardShortcut("w", modifiers: [.command, .shift])
        static let minimizeWindow = KeyboardShortcut("m", modifiers: [.command])
        static let nextWindow = KeyboardShortcut("`", modifiers: [.command])
        static let previousWindow = KeyboardShortcut("`", modifiers: [.command, .shift])
    }

    // MARK: - Developer Tools

    enum Developer {
        static let toggleDevTools = KeyboardShortcut("i", modifiers: [.command, .option])
        static let toggleConsole = KeyboardShortcut("j", modifiers: [.command, .option])
        static let toggleInspector = KeyboardShortcut("c", modifiers: [.command, .option])
        static let toggleNetworkTab = KeyboardShortcut("n", modifiers: [.command, .option])
    }

    // MARK: - Accessibility & Utility

    enum Utility {
        static let showDownloads = KeyboardShortcut("j", modifiers: [.command, .shift])
        static let showPreferences = KeyboardShortcut(",", modifiers: [.command])
        static let showCommandPalette = KeyboardShortcut("k", modifiers: [.command, .shift])
        static let toggleReader = KeyboardShortcut("r", modifiers: [.command, .shift])
        static let printPage = KeyboardShortcut("p", modifiers: [.command])
        static let saveAs = KeyboardShortcut("s", modifiers: [.command, .shift])
    }

    // MARK: - Text Editing (for web forms)

    enum TextEditing {
        static let selectAll = KeyboardShortcut("a", modifiers: [.command])
        static let copy = KeyboardShortcut("c", modifiers: [.command])
        static let paste = KeyboardShortcut("v", modifiers: [.command])
        static let cut = KeyboardShortcut("x", modifiers: [.command])
        static let undo = KeyboardShortcut("z", modifiers: [.command])
        static let redo = KeyboardShortcut("z", modifiers: [.command, .shift])
    }
}

// MARK: - Shortcut Extensions

extension Shortcuts {
    /// Returns all tab selection shortcuts as an array
    static var tabSelectionShortcuts: [KeyboardShortcut] {
        [
            Tab.selectTab1, Tab.selectTab2, Tab.selectTab3, Tab.selectTab4, Tab.selectTab5,
            Tab.selectTab6, Tab.selectTab7, Tab.selectTab8, Tab.selectTab9, Tab.selectLastTab
        ]
    }

    /// Returns navigation shortcuts that should work globally
    static var globalNavigationShortcuts: [KeyboardShortcut] {
        [
            Navigation.goBack, Navigation.goBackAlt,
            Navigation.goForward, Navigation.goForwardAlt,
            Navigation.reload, Navigation.hardReload
        ]
    }

    /// Returns shortcuts that should be available in text fields
    static var textEditingShortcuts: [KeyboardShortcut] {
        [
            TextEditing.selectAll, TextEditing.copy, TextEditing.paste,
            TextEditing.cut, TextEditing.undo, TextEditing.redo
        ]
    }
}

// MARK: - Shortcut Descriptions

extension Shortcuts {
    /// Human-readable descriptions for shortcuts (useful for help/settings)
    enum Descriptions {
        static let shortcutDescriptions: [KeyboardShortcut: String] = [
            Tab.new: "New Tab",
            Tab.close: "Close Tab",
            Tab.reopen: "Reopen Closed Tab",
            Navigation.goBack: "Go Back",
            Navigation.goForward: "Go Forward",
            Navigation.reload: "Reload Page",
            AddressBar.focus: "Focus Address Bar",
            Bookmarks.addBookmark: "Add Bookmark",
            View.toggleFullScreen: "Toggle Full Screen",
            Window.newWindow: "New Window"
            // Add more as needed...
        ]

        static func description(for shortcut: KeyboardShortcut) -> String? {
            shortcutDescriptions[shortcut]
        }
    }
}
