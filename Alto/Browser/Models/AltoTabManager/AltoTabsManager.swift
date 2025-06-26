//
//  AltoTabsManager.swift
//  OpenADK
//
//  Created by StudioMovieGirl
//

import AppKit
import Observation
import OpenADK
import WebKit

// MARK: - TabsManager

/// Manges Tabs for each Window
///
///  Tabs will be stored in Alto in future in order to support tabs being shared between windows (like Arc)
@Observable
open class AltoTabsManager: ADKTabManager {
    public var currentSpace: Space?

    public init(state: AltoState? = nil) {
        let tabLocations = [
            TabLocation(title: "favorites")
        ]
        super.init(state: state, tabLocations: tabLocations)
    }

    public override func addTab(_ tab: ADKTab) {
        AltoData.shared.tabs[tab.id] = tab
    }

    public override func getLocation(_ location: String) -> TabLocation? {
        let spaceLocations = currentSpace?.localLocations ?? []
        let allTabs = tabLocations + spaceLocations
        return allTabs.first(where: { $0.title == location })
    }

    public override func createNewTab(
        url: String = "https://www.google.com/",
        frame: CGRect = .zero,
        location: String
    ) {
        guard let state = state as? AltoState else {
            return
        }
        guard let tabLocation = getLocation(location) else {
            return
        }

        let profile = AltoData.shared.spaceManager.currentSpace?.profile ?? ProfileManager.shared.defaultProfile
        let dataStore = WKWebsiteDataStore(forIdentifier: profile.id)
        let configuration = ADKWebViewConfigurationBase(dataStore: dataStore)

        let newWebView = ADKWebView(frame: frame)
        CookiesManager.shared.setupCookies(for: newWebView)

        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            newWebView.load(request)
        }

        let newTab = ADKTab(state: state)
        newTab.location = tabLocation

        let newWebPage = ADKWebPage(webView: newWebView, state: state, parent: newTab)
        newWebPage.parent = newTab

        newTab.setContent(content: newWebPage)

        let tabRep = TabRepresentation(id: newTab.id, index: tabLocation.tabs.count)
        newTab.tabRepresentation = tabRep

        addTab(newTab)

        tabLocation.appendTabRep(tabRep)
        setActiveTab(newTab)
    }
}
