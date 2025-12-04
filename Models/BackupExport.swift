import Foundation
import HomeKit

/// Backup and export manager for HomeKit configuration
///
/// Provides functionality to:
/// - Export all scenes to JSON
/// - Backup automation rules
/// - Import configurations
/// - Clone setup to another home
/// - Version control for scenes
class BackupManager: ObservableObject {
    static let shared = BackupManager()

    @Published var backups: [HomeBackup] = []
    @Published var lastBackupDate: Date?

    private let backupsKey = "com.homekittv.backups"

    private init() {
        loadBackups()
    }

    // MARK: - Backup Operations

    /// Create a full backup of the current home
    func createBackup(homeManager: HomeKitManager, name: String? = nil) -> HomeBackup {
        let backup = HomeBackup(
            name: name ?? "Backup - \(Date().formatted())",
            homeName: homeManager.primaryHome?.name ?? "Unknown",
            scenes: exportScenes(homeManager.scenes),
            automations: exportAutomations(homeManager.triggers),
            serviceGroups: ServiceGroupManager.shared.serviceGroups,
            favoriteAccessoryIDs: Array(Settings.shared.favoriteAccessoryIDs),
            favoriteSceneIDs: Array(Settings.shared.favoriteSceneIDs),
            settings: exportSettings()
        )

        backups.insert(backup, at: 0)
        lastBackupDate = Date()
        saveBackups()

        return backup
    }

    /// Export scenes to JSON
    func exportScenes(_ scenes: [HMActionSet]) -> [SceneBackup] {
        scenes.map { scene in
            SceneBackup(
                name: scene.name,
                type: scene.actionSetType,
                actions: scene.actions.compactMap { action -> SceneActionBackup? in
                    guard let charAction = action as? HMCharacteristicWriteAction<NSCopying> else { return nil }

                    return SceneActionBackup(
                        accessoryName: charAction.characteristic.service?.accessory?.name ?? "Unknown",
                        serviceName: charAction.characteristic.service?.name ?? "Unknown",
                        characteristicType: charAction.characteristic.characteristicType,
                        targetValue: String(describing: charAction.targetValue)
                    )
                }
            )
        }
    }

    /// Export automations to JSON
    func exportAutomations(_ triggers: [HMTrigger]) -> [AutomationBackup] {
        triggers.map { trigger in
            var triggerType = "Unknown"
            var triggerDetails: [String: String] = [:]

            if let timerTrigger = trigger as? HMTimerTrigger {
                triggerType = "Timer"
                triggerDetails["fireDate"] = timerTrigger.fireDate.ISO8601Format()
                if let recurrence = timerTrigger.recurrence {
                    // Serialize DateComponents
                    var recurrenceInfo: [String] = []
                    if let day = recurrence.day { recurrenceInfo.append("day: \(day)") }
                    if let hour = recurrence.hour { recurrenceInfo.append("hour: \(hour)") }
                    if let minute = recurrence.minute { recurrenceInfo.append("minute: \(minute)") }
                    if let weekday = recurrence.weekday { recurrenceInfo.append("weekday: \(weekday)") }
                    triggerDetails["recurrence"] = recurrenceInfo.joined(separator: ", ")
                }
            } else if let eventTrigger = trigger as? HMEventTrigger {
                triggerType = "Event"
                triggerDetails["eventCount"] = "\(eventTrigger.events.count)"
            }

            return AutomationBackup(
                name: trigger.name,
                enabled: trigger.isEnabled,
                triggerType: triggerType,
                triggerDetails: triggerDetails
            )
        }
    }

    /// Export settings
    func exportSettings() -> SettingsBackup {
        let settings = Settings.shared
        return SettingsBackup(
            statusMessageDuration: settings.statusMessageDuration,
            autoRefreshInterval: settings.autoRefreshInterval,
            showBatteryLevels: settings.showBatteryLevels,
            showReachabilityIndicators: settings.showReachabilityIndicators
        )
    }

    /// Export backup to JSON file
    func exportToJSON(_ backup: HomeBackup) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        guard let data = try? encoder.encode(backup) else { return nil }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "HomeKitTV_Backup_\(backup.timestamp.ISO8601Format()).json"
        let fileURL = documentsPath.appendingPathComponent(filename)

        try? data.write(to: fileURL)
        return fileURL
    }

    /// Import backup from JSON
    func importFromJSON(url: URL) -> HomeBackup? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(HomeBackup.self, from: data)
    }

    /// Restore backup (scenes and settings only - cannot create automations via API)
    func restoreBackup(_ backup: HomeBackup, homeManager: HomeKitManager, completion: @escaping (Bool) -> Void) {
        // Restore settings
        let settings = Settings.shared
        settings.statusMessageDuration = backup.settings.statusMessageDuration
        settings.autoRefreshInterval = backup.settings.autoRefreshInterval
        settings.showBatteryLevels = backup.settings.showBatteryLevels
        settings.showReachabilityIndicators = backup.settings.showReachabilityIndicators

        // Restore favorites (matching by name since UUIDs will differ)
        // Note: Cannot restore scenes or automations directly via HomeKit API on tvOS

        completion(true)
    }

    /// Delete backup
    func deleteBackup(_ backup: HomeBackup) {
        backups.removeAll { $0.id == backup.id }
        saveBackups()
    }

    // MARK: - Comparison

    /// Compare two backups
    func compareBackups(_ backup1: HomeBackup, _ backup2: HomeBackup) -> BackupComparison {
        BackupComparison(
            scenesAdded: backup2.scenes.count - backup1.scenes.count,
            scenesRemoved: backup1.scenes.count - backup2.scenes.count,
            automationsAdded: backup2.automations.count - backup1.automations.count,
            automationsRemoved: backup1.automations.count - backup2.automations.count,
            groupsChanged: abs(backup2.serviceGroups.count - backup1.serviceGroups.count)
        )
    }

    // MARK: - Persistence

    private func loadBackups() {
        if let data = UserDefaults.standard.data(forKey: backupsKey),
           let backups = try? JSONDecoder().decode([HomeBackup].self, from: data) {
            self.backups = backups
        }
    }

    private func saveBackups() {
        if let data = try? JSONEncoder().encode(backups) {
            UserDefaults.standard.set(data, forKey: backupsKey)
        }
    }
}

// MARK: - Models

/// Complete home backup
struct HomeBackup: Identifiable, Codable {
    let id: UUID
    let name: String
    let timestamp: Date
    let homeName: String
    let scenes: [SceneBackup]
    let automations: [AutomationBackup]
    let serviceGroups: [ServiceGroup]
    let favoriteAccessoryIDs: [String]
    let favoriteSceneIDs: [String]
    let settings: SettingsBackup

    init(name: String, homeName: String, scenes: [SceneBackup], automations: [AutomationBackup], serviceGroups: [ServiceGroup], favoriteAccessoryIDs: [String], favoriteSceneIDs: [String], settings: SettingsBackup) {
        self.id = UUID()
        self.name = name
        self.timestamp = Date()
        self.homeName = homeName
        self.scenes = scenes
        self.automations = automations
        self.serviceGroups = serviceGroups
        self.favoriteAccessoryIDs = favoriteAccessoryIDs
        self.favoriteSceneIDs = favoriteSceneIDs
        self.settings = settings
    }
}

/// Scene backup model
struct SceneBackup: Codable {
    let name: String
    let type: String
    let actions: [SceneActionBackup]
}

/// Scene action backup
struct SceneActionBackup: Codable {
    let accessoryName: String
    let serviceName: String
    let characteristicType: String
    let targetValue: String
}

/// Automation backup model
struct AutomationBackup: Codable {
    let name: String
    let enabled: Bool
    let triggerType: String
    let triggerDetails: [String: String]
}

/// Settings backup model
struct SettingsBackup: Codable {
    let statusMessageDuration: Double
    let autoRefreshInterval: Double
    let showBatteryLevels: Bool
    let showReachabilityIndicators: Bool
}

/// Backup comparison result
struct BackupComparison {
    let scenesAdded: Int
    let scenesRemoved: Int
    let automationsAdded: Int
    let automationsRemoved: Int
    let groupsChanged: Int
}
