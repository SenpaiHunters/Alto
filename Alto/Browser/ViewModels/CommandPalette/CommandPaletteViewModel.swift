//
//  CommandPaletteViewModel.swift
//  Alto
//
//  Created by Hunor Zoltáni on 19.06.2025.
//

import Observation
import OpenADK
import Foundation
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
        var searchText: String = ""
        
        /// The icon to display in the search bar based on whether the input is a valid URL.
        ///
        /// Returns "globe" for valid URLs and "magnifyingglass" for search queries.
        var searchIcon: String {
            searchManager.isValidURL(searchText) ? "globe" : "magnifyingglass"
        }
        
        /// Handles the submission of search text or URL.
        ///
        /// Creates a new tab with the entered URL or performs a search using the default search engine.
        /// For valid URLs, the search text is normalized before creating the tab.
        /// Automatically closes the command palette after submission.
        ///
        /// - Parameters:
        ///   - tabManager: The tab manager to create new tabs with.
        ///   - altoState: The app state to update the command palette visibility.
        func handleSubmit(tabManager: TabsManager?, altoState: AltoState) {
            guard let tabManager = tabManager else { return }
            
            if searchManager.isValidURL(searchText) {
                let normalizedSearchText = searchManager.normalizeURL(searchText)
                tabManager.createNewTab(url: normalizedSearchText, location: "unpinned")
            } else {
                if let safeSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    tabManager.createNewTab(url: searchManager.searchEngineURL + safeSearchText, location: "unpinned")
                }
            }
            
            altoState.isShowingCommandPalette = false
        }
        
        /// Handles tapping on a search suggestion.
        ///
        /// Creates a new tab with a search query for the selected suggestion.
        /// Automatically closes the command palette after selection.
        ///
        /// - Parameters:
        ///   - suggestion: The search suggestion that was tapped.
        ///   - tabManager: The tab manager to create new tabs with.
        ///   - altoState: The app state to update the command palette visibility.
        func handleSuggestionTap(suggestion: SearchSuggestion, tabManager: TabsManager?, altoState: AltoState) {
            guard let tabManager = tabManager,
                  let safeSearchText = suggestion.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            
            tabManager.createNewTab(url: searchManager.searchEngineURL + safeSearchText, location: "unpinned")
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
            }
        }
        
        /// Fetches search suggestions for the current search text.
        ///
        /// This method delegates to the search manager to retrieve suggestions
        /// based on the current search text input.
        func fetchSuggestions() {
            searchManager.fetchSuggestions(for: searchText)
        }
    }
}
