//
//  DownloadModels.swift
//  Alto
//
//  Created by Kami on 23/06/2025.
//

import Foundation
import WebKit

// MARK: - DownloadItem

/// Represents a single download item
@Observable
public class DownloadItem: Identifiable, Equatable {
    public let id = UUID()
    public let url: URL
    public let suggestedFilename: String
    public let startTime: Date
    
    public var filename: String
    public var destinationURL: URL?
    public var state: DownloadState = .pending
    public var progress: Double = 0.0
    public var totalBytes: Int64 = 0
    public var receivedBytes: Int64 = 0
    public var speed: Double = 0.0 // bytes per second
    public var timeRemaining: TimeInterval = 0
    public var error: Error?
    

    
    public init(url: URL, suggestedFilename: String) {
        self.url = url
        self.suggestedFilename = suggestedFilename
        self.filename = suggestedFilename
        self.startTime = Date()
    }
    
    public static func == (lhs: DownloadItem, rhs: DownloadItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    
    public var formattedSize: String {
        guard totalBytes > 0 else { return "Unknown size" }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
    
    public var formattedProgress: String {
        let received = ByteCountFormatter.string(fromByteCount: receivedBytes, countStyle: .file)
        let total = totalBytes > 0 ? ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file) : "Unknown"
        return "\(received) / \(total)"
    }
    
    public var formattedSpeed: String {
        guard speed > 0 else { return "" }
        let speedFormatted = ByteCountFormatter.string(fromByteCount: Int64(speed), countStyle: .file)
        return "\(speedFormatted)/s"
    }
    
    public var formattedTimeRemaining: String {
        guard timeRemaining > 0 && timeRemaining.isFinite else { return "" }
        
        if timeRemaining < 60 {
            return "\(Int(timeRemaining))s"
        } else if timeRemaining < 3600 {
            return "\(Int(timeRemaining / 60))m"
        } else {
            let hours = Int(timeRemaining / 3600)
            let minutes = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
    
    public var progressPercentage: String {
        return String(format: "%.0f%%", progress * 100)
    }
    
    public var formattedBytesDownloaded: String {
        return ByteCountFormatter.string(fromByteCount: receivedBytes, countStyle: .file)
    }
    
    public var formattedTotalBytes: String {
        guard totalBytes > 0 else { return "Unknown size" }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }
}

// MARK: - DownloadState

/// Current state of a download
public enum DownloadState: String, CaseIterable {
    case pending = "pending"
    case downloading = "downloading"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
    
    public var isActive: Bool {
        switch self {
        case .pending, .downloading, .paused:
            return true
        case .completed, .failed, .cancelled:
            return false
        }
    }
}

// MARK: - DownloadStatistics

/// Statistics for the download manager
public struct DownloadStatistics {
    public let totalDownloads: Int
    public let activeDownloads: Int
    public let completedDownloads: Int
    public let failedDownloads: Int
    public let totalBytesDownloaded: Int64
    public let currentSpeed: Double
    
    public var formattedTotalBytes: String {
        ByteCountFormatter.string(fromByteCount: totalBytesDownloaded, countStyle: .file)
    }
    
    public var formattedCurrentSpeed: String {
        guard currentSpeed > 0 else { return "0 B/s" }
        let speedFormatted = ByteCountFormatter.string(fromByteCount: Int64(currentSpeed), countStyle: .file)
        return "\(speedFormatted)/s"
    }
} 