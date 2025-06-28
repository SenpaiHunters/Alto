import OpenADK
import SwiftUI

// MARK: - BrowserContentView

struct BrowserContentView: View {
    @Environment(AltoState.self) private var altoState
    @Bindable var preferences: PreferencesManager = .shared

    var data: AltoData {
        AltoData.shared
    }

    var body: some View {
        HStack(spacing: 5) {
            if altoState.sidebar, !altoState.sidebarIsRight {
                sidebar
            }
            VStack(spacing: 5) {
                if !altoState.sidebar {
                    topbar
                        .zIndex(1) // This ensures the spaces and url popups appear over the web content
                }
                content
            }

            if altoState.sidebar, altoState.sidebarIsRight {
                sidebar
            }
        }
        .padding(5)
        .overlay {
            // Extension installation dialog
            if altoState.showExtensionInstallPrompt {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay {
                        ExtensionInstallDialog(
                            extensionName: extractExtensionName(),
                            extensionIcon: extractExtensionIcon(),
                            permissions: extractExtensionPermissions(),
                            onAccept: {
                                if let url = altoState.pendingExtensionURL {
                                    altoState.confirmExtensionInstallation(url)
                                }
                            },
                            onCancel: {
                                altoState.cancelExtensionInstallation()
                            }
                        )
                    }
                    .zIndex(1000)
            }
        }
        .onAppear {
            initializeExtensionsOnStartup()
        }
    }

    @ViewBuilder
    private var topbar: some View {
        HStack(spacing: 2) {
            NavigationButtons

            HorizontalTabsList()
            Spacer()

            AltoButton(action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            }, icon: "plus", active: true)

            DownloadButtonView()

            AltoButton(action: {
                AltoData.shared.spaceManager.newSpace(name: "asdf")
            }, icon: "rectangle.2.swap", active: true)

            // Smart extension button
            AltoButton(action: {
                // Check if current page is a Chrome Web Store extension page
                if let currentTab = altoState.tabManager.currentTab,
                   let webPage = currentTab.content.first as? ADKWebPage,
                   let currentURL = webPage.webView.url {
                    print("🔍 Current URL: \(currentURL)")

                    // Check if it's a Chrome Web Store URL
                    let urlString = currentURL.absoluteString
                    if urlString.contains("chromewebstore.google.com/detail/") ||
                        urlString.contains("chrome.google.com/webstore/detail/") {
                        print("🎯 Detected Chrome Web Store extension page!")
                        print("📦 Setting up extension installation for: \(currentURL)")

                        // Set up extension installation
                        altoState.pendingExtensionURL = currentURL
                        altoState.showExtensionInstallPrompt = true

                        print("✅ Extension install dialog should now be visible")
                    } else {
                        print("📦 Not a Chrome Web Store page, opening extension management")
                        // TODO: Open extension management page
                        print("📋 Available actions:")
                        print("   - Extension management UI")
                        print("   - Installed extensions list")
                        print("   - Extension settings")
                    }
                } else {
                    print("❌ No current tab or webview found")
                }
            }, icon: "puzzlepiece.extension", active: true)
        }
        .frame(height: 30)
    }

    @ViewBuilder
    private var sidebar: some View {
        VStack {
            HStack(spacing: 2) {
                NavigationButtons
            }
            .frame(height: 30)

            Button {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.isShowingCommandPalette = true
                }
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("New Tab")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(5)

            VerticalTabsList()

            Spacer()

            HStack {
                DownloadButtonView()

                Spacer()

                AltoButton(action: {
                    withAnimation(.spring(duration: 0.2)) {
                        altoState.isShowingCommandPalette = true
                    }
                }, icon: "plus", active: true)
                    .frame(height: 30)
            }
        }
        .frame(width: 250)
    }

    @ViewBuilder
    private var content: some View {
        let currentContent = altoState.currentContent

        if let currentContent {
            ForEach(Array(currentContent.enumerated()), id: \.element.id) { _, content in
                // Use TabContentView wrapper to handle blocking popups
                if let webPage = content as? ADKWebPage {
                    TabContentView(webPage: webPage)
                        .cornerRadius(10)
                        .shadow(radius: 4)
                } else {
                    AnyView(content.returnView())
                        .cornerRadius(10)
                        .shadow(radius: 4)
                }
            }
        } else {
            EmptyWebView()
        }
    }

    @ViewBuilder
    private var NavigationButtons: some View {
        if !altoState.sidebarIsRight || !altoState.sidebar {
            MacButtonsView()
                .padding(.leading, 6)
                .frame(width: 70)
        }

        AltoButton(
            action: {
                withAnimation(.spring(duration: 0.2)) {
                    altoState.sidebar.toggle()
                }
            },
            icon: "sidebar.left",
            active: true
        )
        .frame(height: 30)
        .fixedSize()

        if altoState.sidebar {
            Spacer()
        }

        if !altoState.sidebar {
            SpacePickerView(model: SpacePickerViewModel(state: altoState))
        }

        AltoButton(
            action: {
                altoState.tabManager.currentTab?.content[0].goBack()
            },
            icon: "arrow.left",
            active: altoState.tabManager.currentTab?.content[0].canGoBack ?? false
        )
        .frame(height: 30)
        .fixedSize()

        AltoButton(
            action: {
                altoState.tabManager.currentTab?.content[0].goForward()

            },
            icon: "arrow.right",
            active: altoState.tabManager.currentTab?.content[0].canGoForward ?? false
        )
        .frame(height: 30)
        .fixedSize()
    }

    @ViewBuilder
    private var tabsList: some View {}

    // MARK: - Extension Initialization

    /// Initialize extensions at startup
    private func initializeExtensionsOnStartup() {
        Task {
            await ExtensionRuntime.shared.initializeAtStartup()

            // Set up Chrome Web Store integration
            ChromeWebStoreIntegration.shared.setExtensionRuntime(ExtensionRuntime.shared)
        }
    }

    // MARK: - Extension Dialog Helpers

    /// Extract extension name from the pending URL
    /// - Returns: Extension name or fallback
    private func extractExtensionName() -> String {
        guard let url = altoState.pendingExtensionURL else {
            return "Extension"
        }

        // Try to extract extension name from Chrome Web Store URL path
        let path = url.path
        if let match = path.range(of: "/detail/([^/]+)/", options: .regularExpression) {
            let nameSlug = String(path[match]).replacingOccurrences(of: "/detail/", with: "")
                .replacingOccurrences(of: "/", with: "")
            // Convert slug to readable name (replace hyphens with spaces, capitalize)
            return nameSlug.replacingOccurrences(of: "-", with: " ").capitalized
        }

        return "Extension"
    }

    /// Extract extension permissions from the pending URL
    /// - Returns: Array of permissions extracted from the Chrome Web Store page
    private func extractExtensionPermissions() -> [String] {
        guard let currentTab = altoState.tabManager.currentTab,
              let webPage = currentTab.content.first as? ADKWebPage else {
            return []
        }

        // JavaScript to extract permissions from the Chrome Web Store page
        let permissionsExtractionScript = """
        (function() {
            const permissions = [];

            // Look for permissions in the "This extension can:" section
            const permissionSections = [
                // Main permissions section
                'div[data-g-id="permissions"]',
                // Alternative selectors for permissions
                '.h-C-b-p-D-xh-hh',
                '.a-b-f-i-p-R',
                // Look for text that contains permission-like content
                'div:contains("This extension can")',
                'div:contains("Permissions")',
                // More specific selectors
                '[jsname="bN97Pc"]',
                '.e-f-o',
                '.webstore-test-wall-tile-value'
            ];

            // Try different methods to find permissions
            for (const selector of permissionSections) {
                try {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(element => {
                        const text = element.textContent || element.innerText || '';
                        if (text.toLowerCase().includes('permission') || 
                            text.toLowerCase().includes('access') ||
                            text.toLowerCase().includes('read') ||
                            text.toLowerCase().includes('modify')) {

                            // Extract individual permission lines
                            const lines = text.split('\\n').map(line => line.trim()).filter(line => line.length > 0);
                            lines.forEach(line => {
                                if (line.length > 10 && line.length < 200 && 
                                    !line.toLowerCase().includes('permission') &&
                                    !permissions.includes(line)) {
                                    permissions.push(line);
                                }
                            });
                        }
                    });
                } catch (e) {
                    // Continue to next selector if this one fails
                }
            }

            // Look for specific permission patterns in the page
            const permissionPatterns = [
                // Common permission descriptions
                /Read and change all your data on the websites you visit/gi,
                /Read your browsing history/gi,
                /Access your tabs and browsing activity/gi,
                /Read and change your data on [\\w\\s\\.]+/gi,
                /Access data for websites/gi,
                /Communicate with cooperating websites/gi,
                /Access your data for [\\w\\s\\.]+/gi,
                /Store unlimited amount of client-side data/gi,
                /Replace the page you see when opening a new tab/gi,
                /Read and modify bookmarks/gi,
                /Manage your downloads/gi,
                /Access browser tabs/gi,
                /Read and change your data/gi
            ];

            const pageText = document.body.textContent || document.body.innerText || '';
            permissionPatterns.forEach(pattern => {
                const matches = pageText.match(pattern);
                if (matches) {
                    matches.forEach(match => {
                        const cleanMatch = match.trim();
                        if (cleanMatch.length > 10 && !permissions.includes(cleanMatch)) {
                            permissions.push(cleanMatch);
                        }
                    });
                }
            });

            // Look for bullet points or list items that might contain permissions
            const listItems = document.querySelectorAll('li, .bullet, .permission-item, [role="listitem"]');
            listItems.forEach(item => {
                const text = (item.textContent || item.innerText || '').trim();
                if (text.length > 15 && text.length < 150 && 
                    (text.toLowerCase().includes('access') || 
                     text.toLowerCase().includes('read') || 
                     text.toLowerCase().includes('modify') ||
                     text.toLowerCase().includes('data') ||
                     text.toLowerCase().includes('website') ||
                     text.toLowerCase().includes('tab') ||
                     text.toLowerCase().includes('bookmark') ||
                     text.toLowerCase().includes('download') ||
                     text.toLowerCase().includes('history')) &&
                    !permissions.includes(text)) {
                    permissions.push(text);
                }
            });

            // Remove duplicates and clean up
            const uniquePermissions = [...new Set(permissions)]
                .filter(perm => perm.length > 5 && perm.length < 200)
                .map(perm => perm.replace(/^[•·\\-\\*]\\s*/, '').trim()) // Remove bullet points
                .filter(perm => perm.length > 5);

            return uniquePermissions.slice(0, 10); // Limit to 10 permissions max
        })();
        """

        var extractedPermissions: [String] = []

        // Execute JavaScript synchronously to get the permissions
        let semaphore = DispatchSemaphore(value: 0)
        webPage.webView.evaluateJavaScript(permissionsExtractionScript) { result, error in
            if let error {
                print("❌ Error extracting permissions: \(error)")
            } else if let permissions = result as? [String] {
                extractedPermissions = permissions
                print("✅ Extracted \(permissions.count) permissions: \(permissions)")
            } else {
                print("⚠️ No permissions found or unexpected result type")
            }
            semaphore.signal()
        }

        // Wait for the result (with timeout)
        let waitResult = semaphore.wait(timeout: .now() + 2.0)

        if waitResult == .timedOut {
            print("⏰ Permission extraction timed out")
        }

        // If no permissions were extracted, provide some common fallback permissions
        if extractedPermissions.isEmpty {
            print("📝 No permissions extracted, using fallback permissions")
            return [
                "Access data on websites you visit",
                "Read and modify web page content"
            ]
        }

        return extractedPermissions
    }

    /// Extract extension icon from the pending URL
    /// - Returns: Extension icon URL or nil
    private func extractExtensionIcon() -> String? {
        guard let currentTab = altoState.tabManager.currentTab,
              let webPage = currentTab.content.first as? ADKWebPage else {
            return nil
        }

        // Use JavaScript to extract the icon URL from the Chrome Web Store page
        let iconExtractionScript = """
        (function() {
            // Look for the extension icon image with the specific pattern
            const iconImg = document.querySelector('img[alt*="Item logo image"], img.rBxtY, img[src*="googleusercontent.com"]');
            if (iconImg && iconImg.src) {
                // Get the highest resolution version (replace s60 with s128 for better quality)
                let iconUrl = iconImg.src;
                if (iconUrl.includes('=s60')) {
                    iconUrl = iconUrl.replace('=s60', '=s128');
                } else if (iconUrl.includes('=s120')) {
                    iconUrl = iconUrl.replace('=s120', '=s128');
                }
                return iconUrl;
            }
            return null;
        })();
        """

        var extractedIconURL: String?

        // Execute JavaScript synchronously to get the icon URL
        let semaphore = DispatchSemaphore(value: 0)
        webPage.webView.evaluateJavaScript(iconExtractionScript) { result, _ in
            if let iconURL = result as? String, !iconURL.isEmpty {
                extractedIconURL = iconURL
            }
            semaphore.signal()
        }

        // Wait for the result (with timeout)
        _ = semaphore.wait(timeout: .now() + 1.0)

        return extractedIconURL
    }
}

// MARK: - VerticalTabsList

struct VerticalTabsList: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        let location = altoState.tabManager.getLocation("unpinned")!
        ForEach(location.tabs, id: \.id) { tab in
            AltoTabView(model: TabViewModel(
                state: altoState,
                draggingViewModel: DropZoneViewModel(
                    state: altoState,
                    tabLocation: altoState.tabManager.getLocation("unpinned")!
                ),
                tab: tab
            ))
            .frame(maxWidth: altoState.sidebar ? .infinity : 160)
            .frame(height: altoState.sidebar ? 30 : 30)
            .offset(!altoState.sidebar ? CGSize(width: -100, height: 0) : CGSize(width: 0, height: 0))

            // hoverZoneView(model: HoverZoneViewModel(state: altoState, tabLocation: location, index: tab.index))
        }
    }
}

// MARK: - HorizontalTabsList

struct HorizontalTabsList: View {
    @Environment(AltoState.self) private var altoState

    var body: some View {
        let location = altoState.tabManager.getLocation("unpinned")!
        ForEach(location.tabs, id: \.id) { tab in
            AltoTabView(model: TabViewModel(
                state: altoState,
                draggingViewModel: DropZoneViewModel(
                    state: altoState,
                    tabLocation: altoState.tabManager.getLocation("unpinned")!
                ),
                tab: tab
            ))
            .frame(maxWidth: altoState.sidebar ? .infinity : 160)
            .frame(height: altoState.sidebar ? 30 : 30)
            .offset(altoState.sidebar ? CGSize(width: 0, height: -40) : CGSize(width: 0, height: 0))

            // hoverZoneView(model: HoverZoneViewModel(state: altoState, tabLocation: location, index: tab.index))
        }
    }
}
