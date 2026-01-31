//
//  WatchDataStore.swift
//  HomeKitTV Watch App
//
//  Local data cache for watch app
//  Persists favorites and state for offline access
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
class WatchDataStore: ObservableObject {
    static let shared = WatchDataStore()

    // MARK: - Published Properties

    @Published var homeName: String = "Home"
    @Published var favoriteScenes: [WatchScene] = []
    @Published var favoriteAccessories: [WatchAccessory] = []
    @Published var rooms: [WatchRoom] = []
    @Published var lastUpdated: Date?
    @Published var isConnected: Bool = false
    @Published var isSyncing: Bool = false
    @Published var lastError: String?

    // MARK: - Private Properties

    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let homeName = "watchHomeName"
        static let favoriteScenes = "watchFavoriteScenes"
        static let favoriteAccessories = "watchFavoriteAccessories"
        static let rooms = "watchRooms"
        static let lastUpdated = "watchLastUpdated"
    }

    // MARK: - Initialization

    private init() {
        loadCachedData()
    }

    // MARK: - Data Management

    /// Load cached data from UserDefaults
    func loadCachedData() {
        homeName = userDefaults.string(forKey: Keys.homeName) ?? "Home"

        if let scenesData = userDefaults.data(forKey: Keys.favoriteScenes),
           let scenes = try? decoder.decode([WatchScene].self, from: scenesData) {
            favoriteScenes = scenes
        }

        if let accessoriesData = userDefaults.data(forKey: Keys.favoriteAccessories),
           let accessories = try? decoder.decode([WatchAccessory].self, from: accessoriesData) {
            favoriteAccessories = accessories
        }

        if let roomsData = userDefaults.data(forKey: Keys.rooms),
           let decodedRooms = try? decoder.decode([WatchRoom].self, from: roomsData) {
            rooms = decodedRooms
        }

        if let date = userDefaults.object(forKey: Keys.lastUpdated) as? Date {
            lastUpdated = date
        }
    }

    /// Save data to UserDefaults
    func saveToCache() {
        userDefaults.set(homeName, forKey: Keys.homeName)

        if let scenesData = try? encoder.encode(favoriteScenes) {
            userDefaults.set(scenesData, forKey: Keys.favoriteScenes)
        }

        if let accessoriesData = try? encoder.encode(favoriteAccessories) {
            userDefaults.set(accessoriesData, forKey: Keys.favoriteAccessories)
        }

        if let roomsData = try? encoder.encode(rooms) {
            userDefaults.set(roomsData, forKey: Keys.rooms)
        }

        userDefaults.set(lastUpdated, forKey: Keys.lastUpdated)
    }

    /// Update with data received from phone
    func updateWithHomeData(_ data: WatchHomeData) {
        homeName = data.homeName
        favoriteScenes = data.favoriteScenes
        favoriteAccessories = data.favoriteAccessories
        rooms = data.rooms
        lastUpdated = data.lastUpdated
        lastError = nil

        saveToCache()

        // Trigger haptic feedback
        WKInterfaceDevice.current().play(.success)
    }

    /// Update single accessory state
    func updateAccessoryState(_ accessory: WatchAccessory) {
        if let index = favoriteAccessories.firstIndex(where: { $0.id == accessory.id }) {
            favoriteAccessories[index] = accessory
            saveToCache()
        }
    }

    // MARK: - Helpers

    /// Get accessories for a specific room
    func accessories(for room: WatchRoom) -> [WatchAccessory] {
        favoriteAccessories.filter { $0.roomName == room.name }
    }

    /// Check if data is stale (older than 5 minutes)
    var isDataStale: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return Date().timeIntervalSince(lastUpdated) > 300
    }

    /// Format last updated time
    var lastUpdatedFormatted: String {
        guard let lastUpdated = lastUpdated else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
}

// MARK: - WatchKit Haptics Helper

import WatchKit

extension WKInterfaceDevice {
    func playHaptic(_ type: WKHapticType) {
        play(type)
    }
}
