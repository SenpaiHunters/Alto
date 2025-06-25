//
//  DownloadButtonView.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import SwiftUI

// MARK: - DownloadButtonView

/// Download button that shows in the top bar
public struct DownloadButtonView: View {
    @Bindable private var viewModel = DownloadViewModel()
    @State private var isHovered = false

    public init() {}

    public var body: some View {
        Button(action: {
            viewModel.toggleDownloads()
        }) {
            ZStack {
                // Base icon
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isHovered ? .primary : .secondary)

                // Badge for active downloads
                if case let .active(count) = viewModel.downloadButtonState {
                    VStack {
                        HStack {
                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 12, height: 12)

                                Text("\(count)")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .offset(x: 6, y: -6)
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
            }
        }
        .popover(isPresented: $viewModel.isShowingDownloads, arrowEdge: .bottom) {
            DownloadDropdownView(viewModel: viewModel)
        }
        .help("Downloads")
        .keyboardShortcut("d", modifiers: [.command, .shift])
    }
}

// MARK: - DownloadDropdownView

/// Downloads dropdown content
struct DownloadDropdownView: View {
    @Bindable var viewModel: DownloadViewModel
    @State private var animationOffset: CGFloat = -10
    @State private var animationOpacity: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header - matching the original design
            HStack {
                Text("RECENT DOWNLOADS")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(0.5)

                Spacer()

                if viewModel.hasDownloads {
                    Button("Clear") {
                        viewModel.clearCompleted()
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Content
            if viewModel.hasDownloads {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentDownloads, id: \.id) { download in
                        DownloadRowView(download: download, viewModel: viewModel)

                        if download.id != viewModel.recentDownloads.last?.id {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("No downloads yet")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            if viewModel.hasDownloads {
                // Footer - matching the original design
                HStack {
                    Text("View all downloads")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.viewAllDownloads()
                    viewModel.closeDownloads()
                }
            }
        }
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .offset(y: animationOffset)
        .opacity(animationOpacity)
        .onAppear {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                animationOffset = 0
                animationOpacity = 1
            }
        }
    }
}

// MARK: - DownloadRowView

/// Individual download row in the dropdown
struct DownloadRowView: View {
    let download: DownloadItem
    @Bindable var viewModel: DownloadViewModel
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Download icon with state - matching original design
            ZStack {
                Circle()
                    .fill(iconBackgroundColor)
                    .frame(width: 32, height: 32)

                Image(systemName: downloadIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                // Filename
                Text(download.filename)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)

                // Progress info - simplified to avoid compiler error
                progressInfoView

                // Progress bar for active downloads
                if download.state.isActive, download.progress > 0 {
                    ProgressView(value: download.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: progressColor))
                        .frame(height: 2)
                }
            }

            Spacer()

            // Action button - matching original design
            if isHovered {
                Button(action: {
                    handleDownloadAction()
                }) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.primary.opacity(0.03) : Color.clear)
        )
        .onHover { hovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovered
            }
            viewModel.setHoveredDownload(hovered ? download.id : nil)
        }
        .onTapGesture {
            if download.state == .completed {
                viewModel.openInFinder(download)
            }
        }
        .contextMenu {
            downloadContextMenu
        }
    }

    // MARK: - Computed Properties

    private var downloadIcon: String {
        switch download.state {
        case .pending:
            "clock"
        case .downloading:
            "arrow.down"
        case .paused:
            "pause"
        case .completed:
            "checkmark"
        case .failed:
            "exclamationmark"
        case .cancelled:
            "xmark"
        }
    }

    private var iconColor: Color {
        switch download.state {
        case .pending:
            .orange
        case .downloading:
            .blue
        case .paused:
            .yellow
        case .completed:
            .green
        case .failed:
            .red
        case .cancelled:
            .gray
        }
    }

    private var iconBackgroundColor: Color {
        iconColor.opacity(0.15)
    }

    private var progressColor: Color {
        iconColor
    }

    @ViewBuilder
    private var progressInfoView: some View {
        let progressText = download.formattedProgress
        let timeText = download.formattedTimeRemaining
        let hasTime = download.state == .downloading && !timeText.isEmpty
        let speedText = download.state == .downloading && download.speed > 0 ?
            ByteCountFormatter.string(fromByteCount: Int64(download.speed), countStyle: .file) + "/s" : ""

        HStack(spacing: 4) {
            Text(progressText)
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            if hasTime {
                Text("• \(timeText)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            if !speedText.isEmpty {
                Text("• \(speedText)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionIcon: String {
        switch download.state {
        case .downloading:
            "xmark"
        case .paused:
            "play.fill"
        case .failed:
            "arrow.clockwise"
        case .completed:
            "folder"
        default:
            "xmark"
        }
    }

    private func handleDownloadAction() {
        switch download.state {
        case .downloading:
            viewModel.cancelDownload(download)
        case .paused:
            viewModel.resumeDownload(download)
        case .failed:
            // Retry the existing download instead of creating a new one
            DownloadManager.shared.retryDownload(download.id)
        case .completed:
            viewModel.openInFinder(download)
        default:
            viewModel.removeDownload(download)
        }
    }

    @ViewBuilder
    private var downloadContextMenu: some View {
        if download.state == .completed {
            Button("Open in Finder") {
                viewModel.openInFinder(download)
            }

            Button("Show in Downloads Folder") {
                viewModel.viewAllDownloads()
            }

            Divider()
        }

        // Copy URL is available for all downloads
        Button("Copy Download URL") {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(download.url.absoluteString, forType: .string)
        }

        if download.state == .downloading {
            Divider()

            Button("Pause Download") {
                viewModel.pauseDownload(download)
            }

            Button("Cancel Download") {
                viewModel.cancelDownload(download)
            }
        } else if download.state == .paused {
            Divider()

            Button("Resume Download") {
                viewModel.resumeDownload(download)
            }

            Button("Cancel Download") {
                viewModel.cancelDownload(download)
            }
        } else if download.state == .failed {
            Divider()

            Button("Retry Download") {
                // Use the existing download item instead of creating a new one
                DownloadManager.shared.retryDownload(download.id)
            }
        }

        Divider()

        Button("Remove from List") {
            viewModel.removeDownload(download)
        }
    }
}

// MARK: - DownloadButtonState

/// State of the download button
public enum DownloadButtonState: Equatable {
    case empty
    case available
    case active(count: Int)
}

// #Preview {
//     DownloadButtonView()
//         .padding()
//         .background(.regularMaterial)
// }
