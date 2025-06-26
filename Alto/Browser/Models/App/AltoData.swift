//
//  AltoData.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import Observation
import OpenADK
import SwiftUI

// MARK: - Alto

/// Alto is a singleton that allows for global app data such as tab instances or spaces
@Observable
public class AltoData: ADKDataProtocol {
    // MARK: - Properties

    public static let shared = AltoData()

    // Global shared data across browser windows
    public var tabs: [UUID: ADKTab] = [:]
    public var spaces: [Space] = []
    private var Favorites: [UUID: TabLocation] = [:] // TODO: have each profile just contain a tab location

    private var profiles: [Profile] {
        ProfileManager.shared.profiles
    }

    // Managers
    var spaceManager: SpaceManager

    // MARK: - Initialization

    private init() {
        spaceManager = SpaceManager()

        let defaultProfile = ProfileManager.shared.defaultProfile
        spaces = [
            Space(profile: defaultProfile, name: "Latent Space", localLocations: [
                TabLocation(title: "pinned"),
                TabLocation(title: "unpinned")
            ]),
            Space(profile: defaultProfile, name: "The Final Frontier", localLocations: [
                TabLocation(title: "pinned"),
                TabLocation(title: "unpinned")
            ])
        ]
    }

    public func setupFavoriteTabLocations() {
        for profile in profiles {
            Favorites[profile.id] = TabLocation()
        }
    }

    public func getTab(id: UUID) -> ADKTab? {
        guard let tab = tabs.first(where: { $0.key == id })?.value else {
            return nil
        }
        return tab
    }
}
