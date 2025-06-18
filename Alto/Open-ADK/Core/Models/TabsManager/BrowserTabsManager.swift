import Observation
import SwiftUI

// MARK: - BrowserTabsManager

/// Manges Tabs for each Window
///
///  Tabs will be stored in Alto in future in order to support tabs being shared between windows (like Arc)
@Observable
class BrowserTabsManager {
    var state: AltoState?
    var favorites = TabLocation()
    var spaceIndex = 0
    var currentSpace: Space {
        Alto.shared.spaces[spaceIndex]
    }

    // Using dedicated SearchManager for search functionality
    private let searchManager = SearchManager.shared

    init(state: AltoState? = nil) {
        self.state = state
        // self.createNewTab()
    }

    func createNewTab(
        url: String? = nil,
        frame: CGRect = .zero,
        configuration: WKWebViewConfiguration = AltoWebViewConfigurationBase(),
        location: Location = .normal
    ) {
        guard let state else {
            return
        }

        let newWebView = AltoWebView(frame: frame, configuration: configuration)
        Alto.shared.cookieManager.setupCookies(for: newWebView)

        var tabLocation: TabLocation {
            switch location {
            case .favorite: favorites
            case .pinned: currentSpace.pinned
            case .normal: currentSpace.normal
            }
        }
        let urlString = url ?? searchManager.homePageURL

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            newWebView.load(request)
        }

        let newTab = AltoTab(webView: newWebView, state: state)
        let tabRep = TabRepresentation(id: newTab.id, index: tabLocation.tabs.count)
        Alto.shared.tabs[newTab.id] = newTab
        tabLocation.appendTabRep(tabRep)
        currentSpace.currentTab = newTab
    }

    func closeCurrentTab() {
        if let currentTab = currentSpace.currentTab {
            currentTab.closeTab()
        }
    }
}

// MARK: BrowserTabsManager.Location

extension BrowserTabsManager {
    enum Location {
        case favorite
        case pinned
        case normal
    }
}
