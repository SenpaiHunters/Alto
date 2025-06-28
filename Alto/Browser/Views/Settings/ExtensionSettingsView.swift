//
//  ExtensionSettingsView.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import OpenADK
import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExtensionSettingsView

struct ExtensionSettingsView: View {
    @State private var altoState = AltoState.shared
    @State private var showInstallDialog = false
    @State private var showingInstallationAlert = false
    @State private var installationMessage = ""
    @State private var isInstalling = false
    @State private var installError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            if altoState.extensionSupportEnabled {
                extensionManagementSection
                installedExtensionsSection
            } else {
                extensionDisabledSection
            }

            Spacer()
        }
        .padding()
        .fileImporter(
            isPresented: $showInstallDialog,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false,
            onCompletion: handleFileImport
        )
        .alert("Extension Installation", isPresented: $showingInstallationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(installationMessage)
        }
        .alert("Installation Error", isPresented: .constant(installError != nil)) {
            Button("OK") { installError = nil }
        } message: {
            if let error = installError {
                Text(error)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "puzzlepiece.extension")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Extensions")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Toggle("Enable Extensions", isOn: $altoState.extensionSupportEnabled)
                    .toggleStyle(SwitchToggleStyle())
            }

            Text("Manage browser extensions to enhance Alto's functionality")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var extensionManagementSection: some View {
        GroupBox("Install Extensions") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button("Install from Folder...") {
                        showInstallDialog = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)

                    Spacer()

                    if isInstalling {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Text("Select a folder containing an extension's manifest.json file")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Extension Support")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    supportFeatureRow(
                        leading: ("Chrome Extensions", "checkmark.circle.fill", .green),
                        trailing: ("Manifest v2 & v3", "doc.text", .blue)
                    )

                    supportFeatureRow(
                        leading: ("Firefox Extensions", "clock", .orange),
                        trailing: ("Development Mode", "hammer", .purple)
                    )
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var installedExtensionsSection: some View {
        GroupBox("Installed Extensions") {
            if altoState.extensionRuntime.loadedExtensions.isEmpty {
                emptyStateView(
                    icon: "puzzlepiece.extension",
                    title: "No Extensions Installed",
                    subtitle: "Install your first extension to get started",
                    minHeight: 100
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(altoState.extensionRuntime.loadedExtensions.values), id: \.id) { ext in
                            ExtensionRowView(loadedExtension: ext, altoState: altoState)
                        }
                    }
                }
            }
        }
    }

    private var extensionDisabledSection: some View {
        GroupBox {
            emptyStateView(
                icon: "puzzlepiece.extension.fill",
                title: "Extension Support Disabled",
                subtitle: "Enable extension support to install and manage browser extensions",
                minHeight: 120
            )
        }
    }

    private func supportFeatureRow(
        leading: (text: String, icon: String, color: Color),
        trailing: (text: String, icon: String, color: Color)
    ) -> some View {
        HStack {
            Label(leading.text, systemImage: leading.icon)
                .foregroundColor(leading.color)

            Spacer()

            Label(trailing.text, systemImage: trailing.icon)
                .foregroundColor(trailing.color)
        }
        .font(.caption)
    }

    private func emptyStateView(icon: String, title: String, subtitle: String, minHeight: CGFloat) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let extensionURL = urls.first else { return }

            Task {
                do {
                    _ = try await altoState.extensionRuntime.installExtension(from: extensionURL)
                } catch {
                    await MainActor.run {
                        installError = error.localizedDescription
                    }
                }
            }

        case let .failure(error):
            installationMessage = "Failed to select extension folder: \(error.localizedDescription)"
            showingInstallationAlert = true
        }
    }

    /// Show alert when extension has no settings page
    /// - Parameter extensionName: Name of the extension
    private func showNoSettingsAlert(extensionName: String) {
        DispatchQueue.main.async { [self] in
            installationMessage = "The extension \"\(extensionName)\" does not have a settings page."
            showingInstallationAlert = true
        }
    }
}

// MARK: - ExtensionRowView

private struct ExtensionRowView: View {
    let loadedExtension: LoadedExtension
    let altoState: AltoState

    /// Check if extension has an options page or fallback popup configured
    private var hasOptionsPage: Bool {
        // Check for dedicated options page first
        if loadedExtension.manifest.optionsPage != nil ||
            loadedExtension.manifest.options?.page != nil {
            return true
        }

        // Check for fallback popup (action or browserAction)
        if let action = loadedExtension.manifest.action,
           action.default_popup != nil {
            return true
        }

        if let browserAction = loadedExtension.manifest.browserAction,
           browserAction.default_popup != nil {
            return true
        }

        return false
    }

    var body: some View {
        HStack(spacing: 16) {
            ExtensionIconView(loadedExtension: loadedExtension)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(loadedExtension.manifest.name)
                    .font(.headline)

                if let description = loadedExtension.manifest.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text("Version \(loadedExtension.manifest.version)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                // Settings button - only show if extension has options page
                if hasOptionsPage {
                    Button("Settings") {
                        openExtensionSettings()
                    }
                    .buttonStyle(.bordered)
                }

                Toggle("", isOn: Binding(
                    get: { loadedExtension.isEnabled },
                    set: { altoState.extensionRuntime.setExtensionEnabled(loadedExtension.id, enabled: $0) }
                ))
                .toggleStyle(SwitchToggleStyle())

                Button("Remove") {
                    altoState.extensionRuntime.uninstallExtension(loadedExtension.id)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }

    /// Open extension settings by posting notification
    /// This method posts a notification that will be handled by the ExtensionRuntime
    /// to open the extension's options page in a new browser tab
    private func openExtensionSettings() {
        NotificationCenter.default.post(
            name: NSNotification.Name("OpenExtensionSettings"),
            object: nil,
            userInfo: [
                "extensionId": loadedExtension.id,
                "source": "ui"
            ]
        )
    }
}

// MARK: - ExtensionIconView

private struct ExtensionIconView: View {
    let loadedExtension: LoadedExtension
    @State private var iconImage: NSImage?
    @State private var isLoading = true

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.blue.opacity(0.1))
            .overlay(iconContent)
            .onAppear(perform: loadExtensionIcon)
    }

    @ViewBuilder
    private var iconContent: some View {
        if let iconImage {
            Image(nsImage: iconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else if isLoading {
            ProgressView()
                .scaleEffect(0.7)
        } else {
            Image(systemName: "puzzlepiece.extension")
                .foregroundColor(.blue)
        }
    }

    private func loadExtensionIcon() {
        Task {
            await MainActor.run { isLoading = true }
            let image = await loadIconImage()
            await MainActor.run {
                iconImage = image
                isLoading = false
            }
        }
    }

    private func loadIconImage() async -> NSImage? {
        guard let icons = loadedExtension.manifest.icons else { return nil }

        let iconPath = ["128", "48", "32", "16"].compactMap { icons[$0] }.first
        guard let iconPath else { return nil }

        let iconURL = loadedExtension.url.appendingPathComponent(iconPath)
        guard FileManager.default.fileExists(atPath: iconURL.path) else { return nil }

        do {
            let iconData = try Data(contentsOf: iconURL)
            return NSImage(data: iconData)
        } catch {
            print("Failed to load extension icon: \(error)")
            return nil
        }
    }
}
