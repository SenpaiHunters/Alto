//
//  CommandPaletteViewModel.swift
//  Alto
//
//  Created by Hunor Zoltáni on 19.06.2025.
//

import Foundation
import Observation
import OpenADK
import SwiftUI

extension CommandPaletteView {
    /// View model that manages the state and business logic for the command palette.
    ///
    /// This view model encapsulates all the logic related to search text handling,
    /// tab creation, and command palette state management.
    @Observable
    @MainActor
    class ViewModel {
        /// The shared search manager instance used for URL validation and suggestions.
        var searchManager: SearchManager = .shared

        /// The current search text entered by the user.
        var searchText = ""

        /// The currently selected suggestion index for keyboard navigation.
        var selectedIndex: Int = -1

        /// The icon to display in the search bar based on whether the input is a valid URL.
        ///
        /// Returns "globe" for valid URLs and "magnifyingglass" for search queries.
        var searchIcon: String {
            searchManager.isValidURL(searchText) ? "globe" : "magnifyingglass"
        }

        /// Performs a search or navigation with the given text.
        ///
        /// Creates a new tab with the entered URL or performs a search using the default search engine.
        /// For valid URLs, the text is normalized before creating the tab.
        /// Automatically closes the command palette after submission.
        ///
        /// - Parameters:
        ///   - text: The text to search with or navigate to.
        ///   - tabManager: The tab manager to create new tabs with.
        ///   - altoState: The app state to update the command palette visibility.
        func handlePerformSearch(text: String, tabManager: AltoTabsManager?, altoState: AltoState) {
            guard let tabManager else { return }

            if searchManager.isValidURL(text) {
                let normalizedText = searchManager.normalizeURL(text)
                tabManager.createNewTab(url: normalizedText, location: "unpinned")
            } else {
                if let safeSearchText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    tabManager.createNewTab(url: searchManager.searchEngineURL + safeSearchText, location: "unpinned")
                }
            }

            altoState.isShowingCommandPalette = false
        }

        /// Dismisses the command palette with animation.
        ///
        /// - Parameter altoState: The app state to update the command palette visibility.
        func handleDismiss(altoState: AltoState) {
            withAnimation(.spring(duration: 0.2)) {
                altoState.isShowingCommandPalette = false
            }
        }

        /// Handles changes to the command palette visibility state.
        ///
        /// Clears the search text when the palette becomes hidden to provide a fresh start.
        ///
        /// - Parameter newValue: The new visibility state of the command palette.
        func handlePaletteVisibilityChange(newValue: Bool) {
            if !newValue {
                searchText = ""
            } else {
                resetSelection()
            }
        }

        /// Fetches search suggestions for the current search text.
        ///
        /// This method delegates to the search manager to retrieve suggestions
        /// based on the current search text input.
        func fetchSuggestions() {
            searchManager.fetchSuggestions(for: searchText)
            resetSelection()
        }

        /// Handles up arrow key navigation.
        ///
        /// Moves selection up in the suggestions list with wrap-around behavior.
        func handleUpArrow() {
            if !searchManager.suggestions.isEmpty {
                selectedIndex = selectedIndex <= 0 ? searchManager.suggestions.count - 1 : selectedIndex - 1
            }
        }

        /// Handles down arrow key navigation.
        ///
        /// Moves selection down in the suggestions list with wrap-around behavior.
        func handleDownArrow() {
            if !searchManager.suggestions.isEmpty {
                selectedIndex = selectedIndex >= searchManager.suggestions.count - 1 ? 0 : selectedIndex + 1
            }
        }

        /// Resets the selected index to indicate no selection.
        func resetSelection() {
            selectedIndex = -1
        }

        /// Sets the selected index to a specific value.
        ///
        /// - Parameter index: The index to select.
        func setSelectedIndex(_ index: Int) {
            selectedIndex = index
        }
    }
}
