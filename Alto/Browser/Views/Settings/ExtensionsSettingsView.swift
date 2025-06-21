//
//  ExtensionsSettingsView.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExtensionsSettingsView

struct ExtensionsSettingsView: View {
    @Environment(AltoState.self) private var altoState
    @State private var showingFilePicker = false
    @State private var showingExtensionDetails: WebExtension?

    var body: some View {
        @Bindable var bindableState = altoState

        VStack(alignment: .leading, spacing: 16) {
            // Header Section - inline to access bindableState
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "puzzlepiece.extension")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Extensions")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Toggle("Enable Extensions", isOn: $bindableState.isExtensionsEnabled)
                        .toggleStyle(SwitchToggleStyle())
                }

                Text("Manage browser extensions to enhance your browsing experience")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if altoState.isExtensionsEnabled {
                extensionsListSection
                addExtensionSection
            } else {
                disabledExtensionsMessage
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .sheet(item: $showingExtensionDetails) { webExtension in
            ExtensionDetailsSheet(webExtension: webExtension)
        }
    }

    private var extensionsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Installed Extensions")
                .font(.headline)
                .fontWeight(.medium)

            if altoState.loadedExtensions.isEmpty {
                noExtensionsView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(altoState.loadedExtensions, id: \.id) { webExtension in
                        ExtensionRowView(
                            webExtension: webExtension,
                            onDetails: {
                                showingExtensionDetails = webExtension
                            },
                            onRemove: {
                                altoState.unloadExtension(id: webExtension.id)
                            }
                        )
                    }
                }
            }
        }
    }

    private var noExtensionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "puzzlepiece.extension")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .opacity(0.6)

            Text("No Extensions Installed")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("Add extensions to customize your browsing experience")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var addExtensionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add Extension")
                .font(.headline)
                .fontWeight(.medium)

            HStack {
                Button(action: { showingFilePicker = true }) {
                    HStack {
                        Image(systemName: "folder.badge.plus")
                        Text("Load from Folder")
                    }
                }

                Spacer()
            }

            Text("Select a folder containing an unpacked Chrome/Firefox extension")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var disabledExtensionsMessage: some View {
        VStack(spacing: 16) {
            Image(systemName: "puzzlepiece.extension.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
                .opacity(0.7)

            Text("Extensions Disabled")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("Enable extensions in the toggle above to start using browser extensions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            Task {
                await altoState.loadExtension(from: url)
            }
        case let .failure(error):
            print("File import failed: \(error)")
        }
    }
}

// MARK: - ExtensionRowView

struct ExtensionRowView: View {
    let webExtension: WebExtension
    let onDetails: () -> ()
    let onRemove: () -> ()

    var body: some View {
        HStack {
            // Extension Icon
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.gradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "puzzlepiece.extension")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(webExtension.manifest.name)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)

                Text("Version \(webExtension.manifest.version)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let description = webExtension.manifest.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Button("Details", action: onDetails)
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("Remove", action: onRemove)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - ExtensionDetailsSheet

struct ExtensionDetailsSheet: View {
    let webExtension: WebExtension
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Extension Details")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 12) {
                detailRow("Name", webExtension.manifest.name)
                detailRow("Version", webExtension.manifest.version)
                detailRow("Manifest Version", "\(webExtension.manifest.manifestVersion)")

                if let description = webExtension.manifest.description {
                    detailRow("Description", description)
                }

                if let permissions = webExtension.manifest.permissions, !permissions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Permissions:")
                            .font(.headline)

                        ForEach(permissions, id: \.self) { permission in
                            Text("• \(permission)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let hostPermissions = webExtension.manifest.hostPermissions, !hostPermissions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Host Permissions:")
                            .font(.headline)

                        ForEach(hostPermissions, id: \.self) { permission in
                            Text("• \(permission)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 500)
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.headline)
                .frame(width: 120, alignment: .leading)

            Text(value)
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// #Preview {
//    ExtensionsSettingsView()
//        .environment(AltoState())
// }
