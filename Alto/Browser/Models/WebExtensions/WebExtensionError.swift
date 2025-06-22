//
//  WebExtensionError.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import AppKit
import Foundation
import OSLog

// MARK: - ExtensionError

enum ExtensionError: Error, LocalizedError {
    case manifestNotFound
    case invalidManifest(String)
    case unsupportedManifestVersion(Int)
    case missingContentScript(String)
    case invalidPermission(String)
    case permissionDenied(String)
    case extensionLoadError(String)
    case popupLoadError(String)
    case storageError(String)
    case networkError(String)
    case securityError(String)
    case installationError(String)
    case validationError(String)
    case resourceNotFound(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .manifestNotFound:
            "Extension manifest.json not found"
        case let .invalidManifest(details):
            "Invalid manifest: \(details)"
        case let .unsupportedManifestVersion(version):
            "Unsupported manifest version: \(version). Supported versions: 2, 3"
        case let .missingContentScript(script):
            "Content script not found: \(script)"
        case let .invalidPermission(permission):
            "Invalid permission: \(permission)"
        case let .permissionDenied(permission):
            "Permission denied: \(permission)"
        case let .extensionLoadError(error):
            "Extension load error: \(error)"
        case let .popupLoadError(error):
            "Popup load error: \(error)"
        case let .storageError(error):
            "Storage error: \(error)"
        case let .networkError(error):
            "Network error: \(error)"
        case let .securityError(error):
            "Security error: \(error)"
        case let .installationError(error):
            "Installation error: \(error)"
        case let .validationError(error):
            "Validation error: \(error)"
        case let .resourceNotFound(resource):
            "Resource not found: \(resource)"
        case let .apiError(error):
            "API error: \(error)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .manifestNotFound:
            "Ensure the extension contains a valid manifest.json file in the root directory"
        case .invalidManifest:
            "Check the manifest.json syntax and ensure all required fields are present"
        case .unsupportedManifestVersion:
            "Update the extension to use manifest version 2 or 3"
        case .missingContentScript:
            "Ensure all referenced script files exist in the extension directory"
        case .invalidPermission:
            "Check the extension's permission declarations against the supported permissions list"
        case .permissionDenied:
            "Review and approve the extension's permission requirements"
        case .extensionLoadError:
            "Try reloading the extension or check the extension files for corruption"
        case .popupLoadError:
            "Verify the popup HTML file exists and is valid"
        case .storageError:
            "Check available disk space and storage permissions"
        case .networkError:
            "Check your internet connection and try again"
        case .securityError:
            "Review the extension's security settings and permissions"
        case .installationError:
            "Try reinstalling the extension or check file permissions"
        case .validationError:
            "Verify the extension files and manifest are valid"
        case .resourceNotFound:
            "Ensure all referenced resources exist in the extension package"
        case .apiError:
            "Check the extension's API usage and compatibility"
        }
    }

    var failureReason: String? {
        switch self {
        case .manifestNotFound:
            "The extension package does not contain a manifest.json file"
        case let .invalidManifest(details):
            "The manifest.json file contains invalid data: \(details)"
        case let .unsupportedManifestVersion(version):
            "Manifest version \(version) is not supported by this browser"
        case let .missingContentScript(script):
            "The content script file '\(script)' referenced in the manifest does not exist"
        case let .invalidPermission(permission):
            "The permission '\(permission)' is not recognized or supported"
        case let .permissionDenied(permission):
            "The user or system denied the '\(permission)' permission"
        case let .extensionLoadError(error):
            "Failed to load extension: \(error)"
        case let .popupLoadError(error):
            "Failed to load extension popup: \(error)"
        case let .storageError(error):
            "Storage operation failed: \(error)"
        case let .networkError(error):
            "Network operation failed: \(error)"
        case let .securityError(error):
            "Security validation failed: \(error)"
        case let .installationError(error):
            "Extension installation failed: \(error)"
        case let .validationError(error):
            "Extension validation failed: \(error)"
        case let .resourceNotFound(resource):
            "The resource '\(resource)' could not be found"
        case let .apiError(error):
            "Extension API call failed: \(error)"
        }
    }

    // MARK: - Error Categories

    var category: ExtensionErrorCategory {
        switch self {
        case .manifestNotFound,
             .invalidManifest,
             .unsupportedManifestVersion,
             .validationError:
            .manifest
        case .missingContentScript,
             .resourceNotFound:
            .resources
        case .invalidPermission,
             .permissionDenied,
             .securityError:
            .permissions
        case .extensionLoadError,
             .installationError:
            .installation
        case .popupLoadError:
            .popup
        case .storageError:
            .storage
        case .networkError:
            .network
        case .apiError:
            .api
        }
    }

    var severity: ExtensionErrorSeverity {
        switch self {
        case .manifestNotFound,
             .invalidManifest,
             .unsupportedManifestVersion,
             .missingContentScript,
             .installationError:
            .critical
        case .permissionDenied,
             .securityError,
             .validationError:
            .high
        case .extensionLoadError,
             .popupLoadError,
             .storageError,
             .resourceNotFound:
            .medium
        case .invalidPermission,
             .networkError,
             .apiError:
            .low
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .manifestNotFound,
             .invalidManifest,
             .unsupportedManifestVersion,
             .missingContentScript:
            false
        case .permissionDenied,
             .securityError:
            true
        case .extensionLoadError,
             .popupLoadError,
             .storageError,
             .networkError,
             .installationError,
             .validationError,
             .resourceNotFound,
             .apiError,
             .invalidPermission:
            true
        }
    }
}

// MARK: - ExtensionErrorCategory

enum ExtensionErrorCategory {
    case manifest
    case resources
    case permissions
    case installation
    case popup
    case storage
    case network
    case api

    var displayName: String {
        switch self {
        case .manifest:
            "Manifest"
        case .resources:
            "Resources"
        case .permissions:
            "Permissions"
        case .installation:
            "Installation"
        case .popup:
            "Popup"
        case .storage:
            "Storage"
        case .network:
            "Network"
        case .api:
            "API"
        }
    }
}

// MARK: - ExtensionErrorSeverity

enum ExtensionErrorSeverity: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4

    var displayName: String {
        switch self {
        case .low:
            "Low"
        case .medium:
            "Medium"
        case .high:
            "High"
        case .critical:
            "Critical"
        }
    }

    var color: String {
        switch self {
        case .low:
            "blue"
        case .medium:
            "orange"
        case .high:
            "red"
        case .critical:
            "purple"
        }
    }
}

// MARK: - ExtensionErrorReport

struct ExtensionErrorReport {
    let error: ExtensionError
    let extensionId: String?
    let timestamp: Date
    let context: [String: Any]

    init(error: ExtensionError, extensionId: String? = nil, context: [String: Any] = [:]) {
        self.error = error
        self.extensionId = extensionId
        timestamp = Date()
        self.context = context
    }

    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "error_description": error.errorDescription ?? "Unknown error",
            "error_category": error.category.displayName,
            "error_severity": error.severity.displayName,
            "is_recoverable": error.isRecoverable,
            "timestamp": timestamp.timeIntervalSince1970
        ]

        if let extensionId {
            dict["extension_id"] = extensionId
        }

        if let failureReason = error.failureReason {
            dict["failure_reason"] = failureReason
        }

        if let recoverySuggestion = error.recoverySuggestion {
            dict["recovery_suggestion"] = recoverySuggestion
        }

        dict["context"] = context

        return dict
    }
}

// MARK: - ExtensionErrorHandler

@MainActor
final class ExtensionErrorHandler {
    static let shared = ExtensionErrorHandler()

    private var errorReports: [ExtensionErrorReport] = []
    private let maxReports = 100

    private init() {}

    func handle(_ error: ExtensionError, extensionId: String? = nil, context: [String: Any] = [:]) {
        let report = ExtensionErrorReport(error: error, extensionId: extensionId, context: context)

        // Add to reports
        errorReports.append(report)
        if errorReports.count > maxReports {
            errorReports.removeFirst()
        }

        // Log error
        let logger = Logger(subsystem: "Alto.ExtensionManager", category: "ErrorHandler")
        logger
            .error(
                "Extension error: \(error.errorDescription ?? "Unknown") - Category: \(error.category.displayName) - Severity: \(error.severity.displayName)"
            )

        // Handle based on severity
        switch error.severity {
        case .critical:
            handleCriticalError(report)
        case .high:
            handleHighSeverityError(report)
        case .medium:
            handleMediumSeverityError(report)
        case .low:
            handleLowSeverityError(report)
        }
    }

    private func handleCriticalError(_ report: ExtensionErrorReport) {
        // Show alert to user
        showErrorAlert(report)

        // Disable extension if applicable
        if let extensionId = report.extensionId {
            ExtensionManager.shared.toggleExtension(id: extensionId)
        }
    }

    private func handleHighSeverityError(_ report: ExtensionErrorReport) {
        // Show alert to user
        showErrorAlert(report)
    }

    private func handleMediumSeverityError(_ report: ExtensionErrorReport) {
        // Log and potentially show notification
        // Could be handled in UI with less intrusive notification
    }

    private func handleLowSeverityError(_ report: ExtensionErrorReport) {
        // Just log, no user notification needed
    }

    private func showErrorAlert(_ report: ExtensionErrorReport) {
        let alert = NSAlert()
        alert.messageText = "Extension Error"
        alert.informativeText = report.error.errorDescription ?? "An unknown error occurred"

        if let suggestion = report.error.recoverySuggestion {
            alert.informativeText += "\n\n\(suggestion)"
        }

        alert.alertStyle = report.error.severity == .critical ? .critical : .warning
        alert.addButton(withTitle: "OK")

        if report.error.isRecoverable {
            alert.addButton(withTitle: "Retry")
        }

        alert.runModal()
    }

    func getRecentErrors(limit: Int = 10) -> [ExtensionErrorReport] {
        Array(errorReports.suffix(limit))
    }

    func clearErrorReports() {
        errorReports.removeAll()
    }
}
