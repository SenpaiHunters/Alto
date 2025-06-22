//
//  WebExtensionStorage.swift
//  Alto
//
//  Created by Kami on 21/06/2025.
//

import Foundation
import os.log

// MARK: - ExtensionStorageManager

@MainActor
final class ExtensionStorageManager {
    private let logger = Logger(subsystem: "Alto.ExtensionManager", category: "StorageManager")
    private var localStorage: [String: [String: Any]] = [:]
    private var syncStorage: [String: [String: Any]] = [:]
    private var sessionStorage: [String: [String: Any]] = [:]
    private let storageURL: URL
    private let maxStorageSize = 10 * 1024 * 1024 // 10MB per extension
    private let maxSyncStorageSize = 100 * 1024 // 100KB for sync storage

    // Storage change listeners
    private var storageListeners: [String: [(StorageArea, [String: Any]) -> ()]] = [:]

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let altoDir = appSupport.appendingPathComponent("Alto")
        storageURL = altoDir.appendingPathComponent("ExtensionStorage")

        createStorageDirectoryIfNeeded()
        loadStorageFromDisk()
    }

    // MARK: - Public API

    func get(extensionId: String, area: StorageArea, keys: StorageKeys) -> [String: Any] {
        let storage = getStorage(for: area)
        let extensionStorage = storage[extensionId] ?? [:]

        switch keys {
        case .all:
            return extensionStorage
        case let .single(key):
            if let value = extensionStorage[key] {
                return [key: value]
            }
            return [:]
        case let .multiple(keyArray):
            var result: [String: Any] = [:]
            for key in keyArray {
                if let value = extensionStorage[key] {
                    result[key] = value
                }
            }
            return result
        case let .withDefaults(defaults):
            var result = defaults
            for (key, defaultValue) in defaults {
                if let value = extensionStorage[key] {
                    result[key] = value
                } else {
                    result[key] = defaultValue
                }
            }
            return result
        }
    }

    func set(extensionId: String, area: StorageArea, items: [String: Any]) throws {
        var storage = getStorage(for: area)

        if storage[extensionId] == nil {
            storage[extensionId] = [:]
        }

        // Check storage limits
        try validateStorageSize(extensionId: extensionId, area: area, newItems: items, storage: storage)

        var oldValues: [String: Any] = [:]
        var newValues: [String: Any] = [:]

        for (key, value) in items {
            oldValues[key] = storage[extensionId]?[key]
            storage[extensionId]?[key] = value
            newValues[key] = value
        }

        setStorage(for: area, storage: storage)
        saveStorageToDisk(area: area)

        // Notify listeners
        notifyStorageChange(
            extensionId: extensionId,
            area: area,
            changes: createStorageChanges(oldValues: oldValues, newValues: newValues)
        )

        logger.info("Set \(items.count) items for extension \(extensionId) in \(area.rawValue)")
    }

    func remove(extensionId: String, area: StorageArea, keys: [String]) {
        var storage = getStorage(for: area)

        guard var extensionStorage = storage[extensionId] else { return }

        var oldValues: [String: Any] = [:]

        for key in keys {
            oldValues[key] = extensionStorage[key]
            extensionStorage.removeValue(forKey: key)
        }

        storage[extensionId] = extensionStorage
        setStorage(for: area, storage: storage)
        saveStorageToDisk(area: area)

        // Notify listeners
        let changes = createStorageChanges(oldValues: oldValues, newValues: [:])
        notifyStorageChange(extensionId: extensionId, area: area, changes: changes)

        logger.info("Removed \(keys.count) items for extension \(extensionId) in \(area.rawValue)")
    }

    func clear(extensionId: String, area: StorageArea) {
        var storage = getStorage(for: area)
        let oldStorage = storage[extensionId] ?? [:]

        storage[extensionId] = [:]
        setStorage(for: area, storage: storage)
        saveStorageToDisk(area: area)

        // Notify listeners
        let changes = createStorageChanges(oldValues: oldStorage, newValues: [:])
        notifyStorageChange(extensionId: extensionId, area: area, changes: changes)

        logger.info("Cleared all items for extension \(extensionId) in \(area.rawValue)")
    }

    func clearExtensionData(_ extensionId: String) {
        localStorage.removeValue(forKey: extensionId)
        syncStorage.removeValue(forKey: extensionId)
        sessionStorage.removeValue(forKey: extensionId)
        storageListeners.removeValue(forKey: extensionId)

        saveStorageToDisk()

        logger.info("Cleared all data for extension \(extensionId)")
    }

    func getBytesInUse(extensionId: String, area: StorageArea, keys: [String]?) -> Int {
        let storage = getStorage(for: area)
        guard let extensionStorage = storage[extensionId] else { return 0 }

        let relevantData: [String: Any] = if let keys {
            extensionStorage.filter { keys.contains($0.key) }
        } else {
            extensionStorage
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: relevantData)
            return data.count
        } catch {
            logger.error("Failed to calculate bytes in use: \(error.localizedDescription)")
            return 0
        }
    }

    func getStorageQuota(area: StorageArea) -> Int {
        switch area {
        case .local,
             .session:
            maxStorageSize
        case .sync:
            maxSyncStorageSize
        }
    }

    // MARK: - Storage Change Listeners

    func addStorageListener(extensionId: String, listener: @escaping (StorageArea, [String: Any]) -> ()) {
        if storageListeners[extensionId] == nil {
            storageListeners[extensionId] = []
        }
        storageListeners[extensionId]?.append(listener)
    }

    func removeStorageListeners(extensionId: String) {
        storageListeners.removeValue(forKey: extensionId)
    }

    // MARK: - Private Methods

    private func getStorage(for area: StorageArea) -> [String: [String: Any]] {
        switch area {
        case .local:
            localStorage
        case .sync:
            syncStorage
        case .session:
            sessionStorage
        }
    }

    private func setStorage(for area: StorageArea, storage: [String: [String: Any]]) {
        switch area {
        case .local:
            localStorage = storage
        case .sync:
            syncStorage = storage
        case .session:
            sessionStorage = storage
        }
    }

    private func validateStorageSize(
        extensionId: String,
        area: StorageArea,
        newItems: [String: Any],
        storage: [String: [String: Any]]
    ) throws {
        let quota = getStorageQuota(area: area)

        // Calculate current size
        var currentStorage = storage[extensionId] ?? [:]
        for (key, value) in newItems {
            currentStorage[key] = value
        }

        do {
            let data = try JSONSerialization.data(withJSONObject: currentStorage)
            if data.count > quota {
                throw ExtensionError.storageError("Storage quota exceeded. Maximum size: \(quota) bytes")
            }
        } catch let error as ExtensionError {
            throw error
        } catch {
            throw ExtensionError.storageError("Failed to validate storage size: \(error.localizedDescription)")
        }
    }

    private func createStorageChanges(oldValues: [String: Any], newValues: [String: Any]) -> [String: Any] {
        var changes: [String: Any] = [:]

        // Handle removed values
        for (key, oldValue) in oldValues {
            if newValues[key] == nil {
                changes[key] = ["oldValue": oldValue]
            }
        }

        // Handle new and changed values
        for (key, newValue) in newValues {
            var change: [String: Any] = ["newValue": newValue]
            if let oldValue = oldValues[key] {
                change["oldValue"] = oldValue
            }
            changes[key] = change
        }

        return changes
    }

    private func notifyStorageChange(extensionId: String, area: StorageArea, changes: [String: Any]) {
        guard let listeners = storageListeners[extensionId] else { return }

        for listener in listeners {
            listener(area, changes)
        }
    }

    private func createStorageDirectoryIfNeeded() {
        do {
            try FileManager.default.createDirectory(
                at: storageURL,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("Failed to create storage directory: \(error.localizedDescription)")
        }
    }

    private func loadStorageFromDisk() {
        loadStorage(area: .local)
        loadStorage(area: .sync)
        // Session storage is not persisted
    }

    private func loadStorage(area: StorageArea) {
        let fileURL = storageURL.appendingPathComponent("\(area.rawValue).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let storage = try JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] ?? [:]
            setStorage(for: area, storage: storage)
            logger.info("Loaded \(area.rawValue) storage from disk")
        } catch {
            logger.error("Failed to load \(area.rawValue) storage: \(error.localizedDescription)")
        }
    }

    private func saveStorageToDisk() {
        saveStorageToDisk(area: .local)
        saveStorageToDisk(area: .sync)
        // Session storage is not persisted
    }

    private func saveStorageToDisk(area: StorageArea) {
        let fileURL = storageURL.appendingPathComponent("\(area.rawValue).json")
        let storage = getStorage(for: area)

        do {
            let data = try JSONSerialization.data(withJSONObject: storage, options: .prettyPrinted)
            try data.write(to: fileURL)
        } catch {
            logger.error("Failed to save \(area.rawValue) storage: \(error.localizedDescription)")
        }
    }

    // MARK: - Migration and Backup

    func exportExtensionData(extensionId: String) -> [String: Any]? {
        var exportData: [String: Any] = [:]

        if let localData = localStorage[extensionId], !localData.isEmpty {
            exportData["local"] = localData
        }

        if let syncData = syncStorage[extensionId], !syncData.isEmpty {
            exportData["sync"] = syncData
        }

        return exportData.isEmpty ? nil : exportData
    }

    func importExtensionData(extensionId: String, data: [String: Any]) throws {
        if let localData = data["local"] as? [String: Any] {
            try set(extensionId: extensionId, area: .local, items: localData)
        }

        if let syncData = data["sync"] as? [String: Any] {
            try set(extensionId: extensionId, area: .sync, items: syncData)
        }

        logger.info("Imported data for extension \(extensionId)")
    }
}

// MARK: - StorageArea

enum StorageArea: String, CaseIterable {
    case local
    case sync
    case session
}

// MARK: - StorageKeys

enum StorageKeys {
    case all
    case single(String)
    case multiple([String])
    case withDefaults([String: Any])
}
