//
//  HomeKitFocusFilter.swift
//  HomeKitTV
//
//  Focus Filter support for iOS Focus modes
//  Automatically adjust HomeKit behavior based on Focus (Sleep, Work, etc.)
//  Created by Jordan Koch on 2026-01-31.
//  Copyright © 2026 Jordan Koch. All rights reserved.
//

import AppIntents
import SwiftUI

// MARK: - HomeKit Focus Filter

struct HomeKitFocusFilter: SetFocusFilterIntent {
    static var title: LocalizedStringResource = "Set HomeKit Focus"
    static var description: IntentDescription? = IntentDescription(
        "Configure how HomeKit behaves during this Focus mode"
    )

    // Parameters for the focus filter
    @Parameter(title: "Enable Notifications", default: true)
    var enableNotifications: Bool

    @Parameter(title: "Show Favorites Only", default: false)
    var showFavoritesOnly: Bool

    @Parameter(title: "Auto-Run Scene")
    var autoRunScene: SceneFocusEntity?

    @Parameter(title: "Suppress Alerts", default: false)
    var suppressAlerts: Bool

    @Parameter(title: "Dim Display", default: false)
    var dimDisplay: Bool

    static var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "HomeKit Settings",
            subtitle: "Customize HomeKit behavior for this Focus",
            image: .init(systemName: "house.fill")
        )
    }

    func perform() async throws -> some IntentResult {
        // Save focus filter settings
        let settings = FocusFilterSettings(
            enableNotifications: enableNotifications,
            showFavoritesOnly: showFavoritesOnly,
            autoRunSceneId: autoRunScene?.id,
            suppressAlerts: suppressAlerts,
            dimDisplay: dimDisplay
        )

        await FocusFilterManager.shared.applySettings(settings)

        // Auto-run scene if configured
        if let sceneId = autoRunScene?.id {
            NotificationCenter.default.post(
                name: .runSceneFromFocusFilter,
                object: nil,
                userInfo: ["sceneId": sceneId]
            )
        }

        return .result()
    }
}

// MARK: - Scene Focus Entity

struct SceneFocusEntity: AppEntity {
    var id: String
    var name: String
    var iconName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Scene")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            image: .init(systemName: iconName)
        )
    }

    static var defaultQuery = SceneFocusEntityQuery()
}

struct SceneFocusEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [SceneFocusEntity] {
        let scenes = await FocusFilterManager.shared.getAllScenes()
        return scenes.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [SceneFocusEntity] {
        await FocusFilterManager.shared.getAllScenes()
    }
}

// MARK: - Focus Filter Settings

struct FocusFilterSettings: Codable {
    let enableNotifications: Bool
    let showFavoritesOnly: Bool
    let autoRunSceneId: String?
    let suppressAlerts: Bool
    let dimDisplay: Bool

    static let `default` = FocusFilterSettings(
        enableNotifications: true,
        showFavoritesOnly: false,
        autoRunSceneId: nil,
        suppressAlerts: false,
        dimDisplay: false
    )
}

// MARK: - Focus Filter Manager

@MainActor
class FocusFilterManager: ObservableObject {
    static let shared = FocusFilterManager()

    @Published private(set) var currentSettings: FocusFilterSettings = .default
    @Published private(set) var isFocusActive: Bool = false

    private let settingsKey = "focusFilterSettings"

    private init() {
        loadSettings()
    }

    // Apply new focus filter settings
    func applySettings(_ settings: FocusFilterSettings) {
        currentSettings = settings
        isFocusActive = true
        saveSettings()

        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .focusFilterSettingsChanged,
            object: nil,
            userInfo: ["settings": settings]
        )
    }

    // Reset to default settings (when focus ends)
    func resetSettings() {
        currentSettings = .default
        isFocusActive = false
        saveSettings()

        NotificationCenter.default.post(
            name: .focusFilterSettingsChanged,
            object: nil,
            userInfo: ["settings": FocusFilterSettings.default]
        )
    }

    // Get all available scenes for focus filter
    func getAllScenes() -> [SceneFocusEntity] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.HomeKitTV"),
              let data = userDefaults.data(forKey: "focusScenes"),
              let scenes = try? JSONDecoder().decode([SceneFocusData].self, from: data) else {
            // Return sample scenes if no data available
            return [
                SceneFocusEntity(id: "sleep", name: "Good Night", iconName: "moon.stars.fill"),
                SceneFocusEntity(id: "work", name: "Work Mode", iconName: "desktopcomputer"),
                SceneFocusEntity(id: "movie", name: "Movie Time", iconName: "tv.fill"),
                SceneFocusEntity(id: "morning", name: "Good Morning", iconName: "sunrise.fill")
            ]
        }

        return scenes.map {
            SceneFocusEntity(id: $0.id, name: $0.name, iconName: $0.iconName)
        }
    }

    // Save scenes for focus filter selection
    func saveScenes(_ scenes: [SceneFocusEntity]) {
        guard let userDefaults = UserDefaults(suiteName: "group.com.jordankoch.HomeKitTV") else { return }

        let sceneData = scenes.map { SceneFocusData(id: $0.id, name: $0.name, iconName: $0.iconName) }
        if let encoded = try? JSONEncoder().encode(sceneData) {
            userDefaults.set(encoded, forKey: "focusScenes")
        }
    }

    // Private helpers
    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(currentSettings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(FocusFilterSettings.self, from: data) {
            currentSettings = settings
        }
    }
}

// MARK: - Codable Types

struct SceneFocusData: Codable {
    let id: String
    let name: String
    let iconName: String
}

// MARK: - Notification Names

extension Notification.Name {
    static let runSceneFromFocusFilter = Notification.Name("runSceneFromFocusFilter")
    static let focusFilterSettingsChanged = Notification.Name("focusFilterSettingsChanged")
}

// MARK: - View Modifier for Focus Filter

struct FocusFilterAwareModifier: ViewModifier {
    @ObservedObject var focusManager = FocusFilterManager.shared

    func body(content: Content) -> some View {
        content
            .opacity(focusManager.currentSettings.dimDisplay ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: focusManager.currentSettings.dimDisplay)
    }
}

extension View {
    func focusFilterAware() -> some View {
        modifier(FocusFilterAwareModifier())
    }
}
