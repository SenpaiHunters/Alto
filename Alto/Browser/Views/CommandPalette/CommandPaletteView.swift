//
//  CommandPaletteView.swift
//  Alto
//
//  Created by Hunor Zoltáni on 19.06.2025.
//

import SwiftUI
import OpenADK

struct CommandPaletteView: View {
    @Environment(AltoState.self) private var altoState
    @State private var searchManager: SearchManager = .shared
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
//            Dimming Layer
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(duration: 0.2)) {
                        altoState.isShowingCommandPalette = false
                    }
                }
            
            VStack {
                VStack(spacing: 0) {
//                    MARK: - Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: searchManager.isValidURL(searchText) ? "globe" : "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Search or enter address", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .regular))
                            .focused($isSearchFocused)
                            .onSubmit {
                                if let tabManager = altoState.tabManager as? TabsManager {
                                    if searchManager.isValidURL(searchText) {
                                        tabManager.createNewTab(url: searchText, location: "unpinned")
                                    } else {
                                        if let safeSearchText = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                                            tabManager.createNewTab(url: searchManager.searchEngineURL+safeSearchText,location: "unpinned")
                                        }
                                    }
                                    
                                    altoState.isShowingCommandPalette = false
                                }
                            }
                            .onKeyPress(.escape) {
                                withAnimation(.spring(duration: 0.2)) {
                                    altoState.isShowingCommandPalette = false
                                }
                                return .handled
                            }
                            .onChange(of: altoState.isShowingCommandPalette) { oldValue, newValue in
                                searchText = ""
                                
//                                Fixes: Sometimes the Search Bar can become unfocused.
                                if newValue {
                                    isSearchFocused = true
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
//                    MARK: - Suggestions List
                    if !searchManager.suggestions.isEmpty {
                        Divider()
                            .frame(height: 0.5)
                            .background(Color.secondary.opacity(0.1))
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 0) {
                            ForEach(searchManager.suggestions) { suggestion in
                                SuggestionRow(suggestion: suggestion, isSelected: false)
                                    .onTapGesture {
                                        if let tabManager = altoState.tabManager as? TabsManager,
                                           let safeSearchText = suggestion.text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                                            tabManager.createNewTab(url: searchManager.searchEngineURL+safeSearchText,location: "unpinned")
                                            altoState.isShowingCommandPalette = false
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(maxWidth: 580)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.15), radius: 24, x: 0, y: 12)
                .animation(.bouncy.delay(0.1).speed(1.5), value: searchManager.suggestions)
                .task(id: searchText) {
                    searchManager.fetchSuggestions(for: searchText)
                }
                
                Spacer()
            }
            .padding(.top, 250)
        }
        .allowsHitTesting(altoState.isShowingCommandPalette)
        .opacity(altoState.isShowingCommandPalette ? 1.0 : 0.0)
    }
}
