//
//  ExtensionInstallDialog.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import OpenADK
import SwiftUI

// MARK: - ExtensionInstallDialog

/// Extension installation confirmation dialog
struct ExtensionInstallDialog: View {
    let extensionName: String
    let extensionIcon: String?
    let permissions: [String]
    let onAccept: () -> ()
    let onCancel: () -> ()

    var body: some View {
        VStack(spacing: 24) {
            // Header with icons
            HStack(spacing: 20) {
                // Alto icon
                Image("Logo")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Arrow
                Image(systemName: "arrow.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.secondary)

                // Extension icon
                ExtensionIconPlaceholder(iconPath: extensionIcon)
                    .frame(width: 80, height: 80)
            }
            .padding(.horizontal)

            // Title
            Text("Add the \"\(extensionName)\" extension to Alto?")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            // Permissions section
            if permissions.isEmpty {
                Text("This extension requires no special permissions.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("This extension requires the following permissions:")
                        .font(.body)
                        .foregroundColor(.primary)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(permissions, id: \.self) { permission in
                                PermissionRow(permission: permission)
                            }
                        }
                    }
                    .frame(maxHeight: 120)
                    .padding(.leading)
                }
            }

            // Buttons
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(SecondaryButtonStyle())
                .frame(minWidth: 100)

                Button("Add Extension") {
                    onAccept()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(PrimaryButtonStyle())
                .frame(minWidth: 120)
            }
        }
        .padding(32)
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

// MARK: - PermissionRow

private struct PermissionRow: View {
    let permission: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: permissionIcon)
                .foregroundColor(permissionColor)
                .frame(width: 16)

            Text(permissionDescription)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
    }

    private var permissionIcon: String {
        switch permission.lowercased() {
        case let p where p.contains("tabs"):
            "square.stack.3d.up"
        case let p where p.contains("storage"):
            "internaldrive"
        case let p where p.contains("webrequest"):
            "network"
        case let p where p.contains("cookies"):
            "checkerboard.shield"
        case let p where p.contains("history"):
            "clock.arrow.circlepath"
        case let p where p.contains("bookmarks"):
            "book"
        case let p where p.contains("notifications"):
            "bell"
        case let p where p.contains("downloads"):
            "arrow.down.circle"
        case let p where p.contains("contextmenus"):
            "ellipsis.circle"
        case let p where p.contains("activetab"):
            "doc.text"
        case let p where p.contains("all_urls") || p.contains("<all_urls>"):
            "globe"
        default:
            "gear"
        }
    }

    private var permissionColor: Color {
        switch permission.lowercased() {
        case let p where p.contains("all_urls") || p.contains("<all_urls>"):
            .orange
        case let p where p.contains("webrequest"):
            .red
        case let p where p.contains("cookies"):
            .yellow
        default:
            .blue
        }
    }

    private var permissionDescription: String {
        switch permission.lowercased() {
        case "tabs":
            "Access and control browser tabs"
        case "storage":
            "Store data locally"
        case "webrequest":
            "Monitor and modify web requests"
        case "webRequestBlocking":
            "Block or modify web requests"
        case "cookies":
            "Read and modify cookies"
        case "history":
            "Access browsing history"
        case "bookmarks":
            "Read and modify bookmarks"
        case "notifications":
            "Display notifications"
        case "downloads":
            "Manage downloads"
        case "contextMenus":
            "Add items to context menus"
        case "activeTab":
            "Access the active tab"
        case let p where p.contains("all_urls") || p.contains("<all_urls>"):
            "Access data on all websites"
        case let p where p.contains("://"):
            "Access data on \(permission)"
        default:
            permission.capitalized
        }
    }
}

// MARK: - ExtensionIconPlaceholder

private struct ExtensionIconPlaceholder: View {
    let iconPath: String?

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.green.opacity(0.1))
            .overlay(
                Group {
                    if let iconPath {
                        // Check if it's a URL (starts with http)
                        if iconPath.hasPrefix("http") {
                            // Load from network URL
                            AsyncImage(url: URL(string: iconPath)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                        } else {
                            // Load from local file path
                            if let nsImage = NSImage(contentsOfFile: iconPath) {
                                Image(nsImage: nsImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else {
                                Image(systemName: "cube.box")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                            }
                        }
                    } else {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                    }
                }
            )
    }
}

// MARK: - PrimaryButtonStyle

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
    }
}

// MARK: - SecondaryButtonStyle

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.1))
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Preview

#Preview {
    ExtensionInstallDialog(
        extensionName: "Tiny Tycoon",
        extensionIcon: nil,
        permissions: ["tabs", "storage", "<all_urls>"],
        onAccept: {},
        onCancel: {}
    )
    .frame(width: 600, height: 400)
}
