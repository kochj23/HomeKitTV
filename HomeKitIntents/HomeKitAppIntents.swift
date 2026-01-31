//
//  HomeKitAppIntents.swift
//  HomeKitTV
//
//  App Intents for Siri Shortcuts integration
//  "Hey Siri, run Good Morning scene" / "Hey Siri, turn off living room lights"
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import AppIntents
import SwiftUI

// MARK: - Run Scene Intent

struct RunSceneIntent: AppIntent {
    static var title: LocalizedStringResource = "Run HomeKit Scene"
    static var description = IntentDescription("Run a HomeKit scene in your home")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Scene")
    var scene: SceneEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Run \(\.$scene)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Execute the scene via the shared HomeKit manager
        let success = await HomeKitIntentHandler.shared.executeScene(id: scene.id)

        if success {
            return .result(dialog: "Running \(scene.name)")
        } else {
            throw HomeKitIntentError.sceneExecutionFailed
        }
    }
}

// MARK: - Toggle Accessory Intent

struct ToggleAccessoryIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle HomeKit Device"
    static var description = IntentDescription("Turn a HomeKit device on or off")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Device")
    var accessory: AccessoryEntity

    @Parameter(title: "Turn On", default: true)
    var turnOn: Bool

    static var parameterSummary: some ParameterSummary {
        When(\.$turnOn, .equalTo, true) {
            Summary("Turn on \(\.$accessory)")
        } otherwise: {
            Summary("Turn off \(\.$accessory)")
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let success = await HomeKitIntentHandler.shared.setAccessoryPower(id: accessory.id, on: turnOn)

        if success {
            let state = turnOn ? "on" : "off"
            return .result(dialog: "Turned \(accessory.name) \(state)")
        } else {
            throw HomeKitIntentError.accessoryControlFailed
        }
    }
}

// MARK: - Set Brightness Intent

struct SetBrightnessIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Light Brightness"
    static var description = IntentDescription("Set the brightness of a HomeKit light")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Light")
    var accessory: AccessoryEntity

    @Parameter(title: "Brightness", default: 100)
    var brightness: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$accessory) to \(\.$brightness)%")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let clampedBrightness = max(0, min(100, brightness))
        let success = await HomeKitIntentHandler.shared.setAccessoryBrightness(id: accessory.id, brightness: clampedBrightness)

        if success {
            return .result(dialog: "Set \(accessory.name) to \(clampedBrightness)%")
        } else {
            throw HomeKitIntentError.accessoryControlFailed
        }
    }
}

// MARK: - Set Thermostat Intent

struct SetThermostatIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Thermostat Temperature"
    static var description = IntentDescription("Set the target temperature of a thermostat")

    static var openAppWhenRun: Bool = false

    @Parameter(title: "Thermostat")
    var accessory: AccessoryEntity

    @Parameter(title: "Temperature")
    var temperature: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Set \(\.$accessory) to \(\.$temperature)°")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let success = await HomeKitIntentHandler.shared.setThermostatTemperature(id: accessory.id, temperature: temperature)

        if success {
            return .result(dialog: "Set \(accessory.name) to \(Int(temperature))°")
        } else {
            throw HomeKitIntentError.accessoryControlFailed
        }
    }
}

// MARK: - Get Home Status Intent

struct GetHomeStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Home Status"
    static var description = IntentDescription("Get the current status of your smart home")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let status = await HomeKitIntentHandler.shared.getHomeStatus()

        return .result(dialog: """
            \(status.homeName): \
            \(status.accessoryCount) devices, \
            \(status.lightsOn) lights on, \
            \(status.sceneCount) scenes available
            """)
    }
}

// MARK: - Scene Entity

struct SceneEntity: AppEntity {
    var id: String
    var name: String
    var iconName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Scene")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: iconName))
    }

    static var defaultQuery = SceneEntityQuery()
}

struct SceneEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SceneEntity] {
        let allScenes = await HomeKitIntentHandler.shared.getAllScenes()
        return allScenes.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [SceneEntity] {
        await HomeKitIntentHandler.shared.getAllScenes()
    }
}

// MARK: - Accessory Entity

struct AccessoryEntity: AppEntity {
    var id: String
    var name: String
    var roomName: String?
    var categoryType: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Device")
    }

    var displayRepresentation: DisplayRepresentation {
        let subtitle = roomName ?? categoryType.capitalized
        return DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(subtitle)",
            image: .init(systemName: iconForCategory(categoryType))
        )
    }

    static var defaultQuery = AccessoryEntityQuery()

    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "light": return "lightbulb.fill"
        case "outlet": return "poweroutlet.type.b.fill"
        case "thermostat": return "thermometer"
        case "fan": return "fan.fill"
        case "lock": return "lock.fill"
        default: return "questionmark.circle"
        }
    }
}

struct AccessoryEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [AccessoryEntity] {
        let allAccessories = await HomeKitIntentHandler.shared.getAllAccessories()
        return allAccessories.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [AccessoryEntity] {
        await HomeKitIntentHandler.shared.getFavoriteAccessories()
    }
}

// MARK: - Intent Handler

@MainActor
class HomeKitIntentHandler {
    static let shared = HomeKitIntentHandler()

    private init() {}

    struct HomeStatus {
        let homeName: String
        let accessoryCount: Int
        let lightsOn: Int
        let sceneCount: Int
    }

    // Execute a scene by ID
    func executeScene(id: String) async -> Bool {
        // This would integrate with HomeKitManager
        // For now, post a notification for the main app to handle
        NotificationCenter.default.post(
            name: .executeSceneFromIntent,
            object: nil,
            userInfo: ["sceneId": id]
        )
        return true
    }

    // Set accessory power state
    func setAccessoryPower(id: String, on: Bool) async -> Bool {
        NotificationCenter.default.post(
            name: .setAccessoryPowerFromIntent,
            object: nil,
            userInfo: ["accessoryId": id, "on": on]
        )
        return true
    }

    // Set accessory brightness
    func setAccessoryBrightness(id: String, brightness: Int) async -> Bool {
        NotificationCenter.default.post(
            name: .setAccessoryBrightnessFromIntent,
            object: nil,
            userInfo: ["accessoryId": id, "brightness": brightness]
        )
        return true
    }

    // Set thermostat temperature
    func setThermostatTemperature(id: String, temperature: Double) async -> Bool {
        NotificationCenter.default.post(
            name: .setThermostatFromIntent,
            object: nil,
            userInfo: ["accessoryId": id, "temperature": temperature]
        )
        return true
    }

    // Get home status
    func getHomeStatus() async -> HomeStatus {
        // Load from shared container or return defaults
        let data = loadSharedData()
        return HomeStatus(
            homeName: data.homeName,
            accessoryCount: data.accessoryCount,
            lightsOn: data.lightsOn,
            sceneCount: data.sceneCount
        )
    }

    // Get all scenes
    func getAllScenes() async -> [SceneEntity] {
        let data = loadSharedData()
        return data.scenes.map {
            SceneEntity(id: $0.id, name: $0.name, iconName: $0.iconName)
        }
    }

    // Get all accessories
    func getAllAccessories() async -> [AccessoryEntity] {
        let data = loadSharedData()
        return data.accessories.map {
            AccessoryEntity(id: $0.id, name: $0.name, roomName: $0.roomName, categoryType: $0.categoryType)
        }
    }

    // Get favorite accessories
    func getFavoriteAccessories() async -> [AccessoryEntity] {
        let data = loadSharedData()
        return data.accessories.filter { $0.isFavorite }.map {
            AccessoryEntity(id: $0.id, name: $0.name, roomName: $0.roomName, categoryType: $0.categoryType)
        }
    }

    // MARK: - Shared Data

    private struct SharedData {
        let homeName: String
        let accessoryCount: Int
        let lightsOn: Int
        let sceneCount: Int
        let scenes: [SharedScene]
        let accessories: [SharedAccessory]
    }

    private struct SharedScene {
        let id: String
        let name: String
        let iconName: String
    }

    private struct SharedAccessory {
        let id: String
        let name: String
        let roomName: String?
        let categoryType: String
        let isFavorite: Bool
    }

    private func loadSharedData() -> SharedData {
        // Load from UserDefaults shared container
        guard let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.HomeKitTV"),
              let data = userDefaults.data(forKey: "intentData"),
              let decoded = try? JSONDecoder().decode(IntentSharedData.self, from: data) else {
            return SharedData(
                homeName: "Home",
                accessoryCount: 0,
                lightsOn: 0,
                sceneCount: 0,
                scenes: [],
                accessories: []
            )
        }

        return SharedData(
            homeName: decoded.homeName,
            accessoryCount: decoded.accessoryCount,
            lightsOn: decoded.lightsOn,
            sceneCount: decoded.sceneCount,
            scenes: decoded.scenes.map { SharedScene(id: $0.id, name: $0.name, iconName: $0.iconName) },
            accessories: decoded.accessories.map {
                SharedAccessory(id: $0.id, name: $0.name, roomName: $0.roomName, categoryType: $0.categoryType, isFavorite: $0.isFavorite)
            }
        )
    }
}

// MARK: - Codable Data for Sharing

struct IntentSharedData: Codable {
    let homeName: String
    let accessoryCount: Int
    let lightsOn: Int
    let sceneCount: Int
    let scenes: [IntentScene]
    let accessories: [IntentAccessory]
}

struct IntentScene: Codable {
    let id: String
    let name: String
    let iconName: String
}

struct IntentAccessory: Codable {
    let id: String
    let name: String
    let roomName: String?
    let categoryType: String
    let isFavorite: Bool
}

// MARK: - Errors

enum HomeKitIntentError: Error, CustomLocalizedStringResourceConvertible {
    case sceneExecutionFailed
    case accessoryControlFailed
    case notAuthorized

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .sceneExecutionFailed:
            return "Failed to run the scene"
        case .accessoryControlFailed:
            return "Failed to control the device"
        case .notAuthorized:
            return "HomeKit access not authorized"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let executeSceneFromIntent = Notification.Name("executeSceneFromIntent")
    static let setAccessoryPowerFromIntent = Notification.Name("setAccessoryPowerFromIntent")
    static let setAccessoryBrightnessFromIntent = Notification.Name("setAccessoryBrightnessFromIntent")
    static let setThermostatFromIntent = Notification.Name("setThermostatFromIntent")
}

// MARK: - App Shortcuts Provider

struct HomeKitShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunSceneIntent(),
            phrases: [
                "Run \(\.$scene) in \(.applicationName)",
                "Activate \(\.$scene) scene",
                "Run \(\.$scene) scene"
            ],
            shortTitle: "Run Scene",
            systemImageName: "wand.and.stars"
        )

        AppShortcut(
            intent: ToggleAccessoryIntent(),
            phrases: [
                "Turn \(\.$turnOn) \(\.$accessory) in \(.applicationName)",
                "Toggle \(\.$accessory)"
            ],
            shortTitle: "Toggle Device",
            systemImageName: "lightbulb.fill"
        )

        AppShortcut(
            intent: GetHomeStatusIntent(),
            phrases: [
                "What's my home status in \(.applicationName)",
                "Home status",
                "Smart home status"
            ],
            shortTitle: "Home Status",
            systemImageName: "house.fill"
        )
    }
}
