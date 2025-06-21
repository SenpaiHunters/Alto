//
//  CommandPaletteView.swift
//  Alto
//
//  Created by Hunor Zoltáni on 19.06.2025.
//

import OpenADK
import SwiftUI

struct CommandPaletteView: View {
    @Environment(AltoState.self) private var altoState
    @FocusState private var isSearchFocused: Bool
    @State private var viewModel: ViewModel = .init()

    var body: some View {
        ZStack {
//            Dimming Layer
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.handleDismiss(altoState: altoState)
                }
                .gesture(WindowDragGesture())

            VStack {
                VStack(spacing: 0) {
//                    MARK: - Search Bar

                    HStack(spacing: 12) {
                        Image(systemName: viewModel.searchIcon)
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16, weight: .medium))

                        TextField("Search or enter address", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .regular))
                            .focused($isSearchFocused)
                            .onSubmit {
                                let textToSubmit = viewModel.selectedIndex == -1 ? viewModel.searchText :
                                    viewModel.searchManager.suggestions[viewModel.selectedIndex].text

                                viewModel.handlePerformSearch(
                                    text: textToSubmit,
                                    tabManager: altoState.tabManager as? TabsManager,
                                    altoState: altoState
                                )
                            }
                            .onChange(of: viewModel.searchText) { _, _ in
                                viewModel.resetSelection()
                            }
                            .onKeyPress(.escape) {
                                viewModel.handleDismiss(altoState: altoState)
                                return .handled
                            }
                            .onKeyPress(.tab) {
                                .handled
                            }
                            .onKeyPress(.upArrow) {
                                viewModel.handleUpArrow()
                                return .handled
                            }
                            .onKeyPress(.downArrow) {
                                viewModel.handleDownArrow()
                                return .handled
                            }
                            .onChange(of: altoState.isShowingCommandPalette) { _, newValue in
                                viewModel.handlePaletteVisibilityChange(newValue: newValue)

//                                Fixes: Sometimes the Search Bar can become unfocused.
                                if newValue {
                                    isSearchFocused = true
                                }
                            }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .onHover { _ in
                        viewModel.resetSelection()
                    }

//                    MARK: - Suggestions List

                    if !viewModel.searchManager.suggestions.isEmpty {
                        Divider()
                            .frame(height: 0.5)
                            .background(Color.secondary.opacity(0.1))
                            .padding(.horizontal, 20)

                        VStack(spacing: 0) {
                            ForEach(
                                Array(viewModel.searchManager.suggestions.enumerated()),
                                id: \.element.id
                            ) { index, suggestion in
                                SuggestionRow(suggestion: suggestion, isSelected: viewModel.selectedIndex == index)
                                    .onTapGesture {
                                        viewModel.handlePerformSearch(
                                            text: suggestion.text,
                                            tabManager: altoState.tabManager as? TabsManager,
                                            altoState: altoState
                                        )
                                    }
                                    .onHover { _ in
                                        viewModel.setSelectedIndex(index)
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
                .animation(.bouncy.delay(0.1).speed(1.5), value: viewModel.searchManager.suggestions)
                .task(id: viewModel.searchText) {
                    viewModel.fetchSuggestions()
                }

                Spacer()
            }
            .padding(.top, 250)
        }
        .allowsHitTesting(altoState.isShowingCommandPalette)
        .opacity(altoState.isShowingCommandPalette ? 1.0 : 0.0)
    }
}
