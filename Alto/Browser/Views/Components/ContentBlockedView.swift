//
//  ContentBlockedView.swift
//  Alto
//
//  Created by Kami on 26/06/2025.
//

import SwiftUI

// MARK: - ContentBlockedView

/// A compact overlay shown when content is blocked by the ad blocker
struct ContentBlockedView: View {
    let blockedURL: String
    let blockerInfo: String
    let onContinueOnce: () -> ()
    let onWhitelistPermanently: () -> ()
    let onCancel: () -> ()

    @State private var showDetails = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea(.all)

            // Compact centered card
            VStack(spacing: 16) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "shield.fill")
                        .font(.title)
                        .foregroundColor(.orange)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Content Blocked")
                            .font(.headline)
                            .fontWeight(.semibold)

                        Text("Blocked by \(blockerInfo)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                // URL (truncated)
                HStack {
                    Text("URL:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(blockedURL)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)

                    Spacer(minLength: 0)
                }

                // Action buttons (horizontal layout)
                HStack(spacing: 8) {
                    Button("Go Back") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape)

                    Button("Continue Once") {
                        onContinueOnce()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)

                    Button("Whitelist") {
                        onWhitelistPermanently()
                    }
                    .buttonStyle(.bordered)
                    .tint(.green)
                }

                // Details toggle
                Button(action: { showDetails.toggle() }) {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.caption)
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                // Collapsible details
                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()

                        Group {
                            Text("⚠️ This content may contain ads, trackers, or malicious scripts.")
                            Text("• **Continue Once**: Load this page without saving preferences")
                            Text("• **Whitelist**: Always allow content from this site")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(20)
            .frame(maxWidth: 480)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        }
        .animation(.easeInOut(duration: 0.2), value: showDetails)
    }
}

// MARK: - Key Event Handling

extension View {
    func onKeyDown(_ key: KeyEquivalent, action: @escaping () -> ()) -> some View {
        background(KeyEventView(key: key, action: action))
    }
}

private struct KeyEventView: NSViewRepresentable {
    let key: KeyEquivalent
    let action: () -> ()

    func makeNSView(context: Context) -> NSView {
        let view = KeyHandlingView()
        view.keyAction = { [key, action] event in
            if event.keyCode == key.keyCode {
                action()
                return true
            }
            return false
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private class KeyHandlingView: NSView {
    var keyAction: ((NSEvent) -> Bool)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if keyAction?(event) != true {
            super.keyDown(with: event)
        }
    }
}

extension KeyEquivalent {
    var keyCode: UInt16 {
        switch self {
        case .escape: 53
        default: 0
        }
    }
}
