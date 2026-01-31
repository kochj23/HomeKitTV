//
//  WatchModels.swift
//  HomeKitTV
//
//  Shared models for Watch Connectivity communication
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import Foundation

// MARK: - Watch Data Transfer Models

/// Lightweight scene representation for watch transfer
struct WatchScene: Codable, Identifiable, Hashable {
    let id: String           // UUID string
    let name: String
    let iconName: String?
    let accessoryCount: Int
    let isFavorite: Bool

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WatchScene, rhs: WatchScene) -> Bool {
        lhs.id == rhs.id
    }
}

/// Lightweight accessory representation for watch transfer
struct WatchAccessory: Codable, Identifiable, Hashable {
    let id: String           // UUID string
    let name: String
    let roomName: String?
    let categoryType: String // "light", "outlet", "switch", "thermostat", "fan", "lock", "sensor"
    let isReachable: Bool
    let isFavorite: Bool

    // State values (simplified for watch)
    var isOn: Bool?
    var brightness: Int?     // 0-100
    var temperature: Double? // For thermostats

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WatchAccessory, rhs: WatchAccessory) -> Bool {
        lhs.id == rhs.id
    }
}

/// Lightweight room representation for watch transfer
struct WatchRoom: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let accessoryCount: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: WatchRoom, rhs: WatchRoom) -> Bool {
        lhs.id == rhs.id
    }
}

/// Complete data package sent to watch
struct WatchHomeData: Codable {
    let homeName: String
    let favoriteScenes: [WatchScene]
    let favoriteAccessories: [WatchAccessory]
    let rooms: [WatchRoom]
    let lastUpdated: Date

    init(homeName: String, favoriteScenes: [WatchScene], favoriteAccessories: [WatchAccessory], rooms: [WatchRoom]) {
        self.homeName = homeName
        self.favoriteScenes = favoriteScenes
        self.favoriteAccessories = favoriteAccessories
        self.rooms = rooms
        self.lastUpdated = Date()
    }
}

// MARK: - Watch Commands

/// Commands sent from watch to phone
enum WatchCommand: String, Codable {
    case executeScene
    case toggleAccessory
    case setAccessoryBrightness
    case setThermostatTemperature
    case refreshData
}

/// Command payload sent from watch
struct WatchCommandPayload: Codable {
    let command: WatchCommand
    let targetId: String?       // Scene or accessory ID
    let value: Double?          // Brightness (0-100) or temperature

    init(command: WatchCommand, targetId: String? = nil, value: Double? = nil) {
        self.command = command
        self.targetId = targetId
        self.value = value
    }
}

/// Response sent back to watch
struct WatchCommandResponse: Codable {
    let success: Bool
    let message: String?
    let updatedAccessory: WatchAccessory?
}

// MARK: - Message Keys

struct WatchMessageKeys {
    static let homeData = "homeData"
    static let command = "command"
    static let response = "response"
    static let updateType = "updateType"
    static let accessoryUpdate = "accessoryUpdate"
    static let sceneExecuted = "sceneExecuted"
}

// MARK: - Update Types

enum WatchUpdateType: String, Codable {
    case fullSync
    case accessoryStateChange
    case sceneExecuted
    case favoritesChanged
}
