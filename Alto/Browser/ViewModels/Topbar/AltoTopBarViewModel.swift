//
//  AltoTopBarViewModel.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Observation

// MARK: - AltoTopBarViewModel

@Observable
final class AltoTopBarViewModel {
    let state: AltoState
    var topbarState: TopbarState = .hidden

    enum TopbarState {
        case hidden
        case active
    }

    init(state: AltoState) {
        self.state = state
    }
}
