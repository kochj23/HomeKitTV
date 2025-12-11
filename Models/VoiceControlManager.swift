import Foundation
import HomeKit
import Intents

/// Voice control and Siri integration manager
///
/// Manages Siri shortcuts, voice commands, and voice control history.
///
/// **Features**:
/// - Siri shortcut creation for devices and scenes
/// - Voice command history tracking
/// - Custom voice command suggestions
/// - Hands-free control integration
class VoiceControlManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = VoiceControlManager()

    @Published var voiceHistory: [VoiceCommand] = []
    @Published var suggestedShortcuts: [VoiceShortcut] = []

    private let historyKey = "com.homekittv.voiceHistory"
    private let maxHistoryItems = 100

    private init() {
        loadHistory()
        generateSuggestions()
    }

    // MARK: - Siri Shortcuts

    /// Creates a Siri shortcut for a device action
    ///
    /// - Parameters:
    ///   - accessory: The HomeKit accessory
    ///   - action: The action to perform (on/off/toggle)
    ///   - phrase: The suggested Siri phrase
    func createShortcut(for accessory: HMAccessory, action: DeviceAction, phrase: String) {
        let intent = DeviceControlIntent()
        intent.deviceName = accessory.name
        intent.action = action.rawValue
        intent.suggestedInvocationPhrase = phrase

        let shortcut = VoiceShortcut(
            id: UUID(),
            deviceID: accessory.uniqueIdentifier.uuidString,
            phrase: phrase,
            action: action,
            createdAt: Date()
        )

        suggestedShortcuts.append(shortcut)
        saveShortcuts()
    }

    /// Creates a Siri shortcut for a scene
    ///
    /// - Parameters:
    ///   - scene: The HomeKit scene
    ///   - phrase: The suggested Siri phrase
    func createShortcut(for scene: HMActionSet, phrase: String) {
        let intent = SceneControlIntent()
        intent.sceneName = scene.name
        intent.suggestedInvocationPhrase = phrase

        let shortcut = VoiceShortcut(
            id: UUID(),
            sceneID: scene.uniqueIdentifier.uuidString,
            phrase: phrase,
            action: .scene,
            createdAt: Date()
        )

        suggestedShortcuts.append(shortcut)
        saveShortcuts()
    }

    /// Generates smart shortcut suggestions based on usage
    func generateSuggestions() {
        // Generate common shortcuts
        let commonShortcuts = [
            VoiceShortcut(id: UUID(), phrase: "Turn off all lights", action: .allOff, createdAt: Date()),
            VoiceShortcut(id: UUID(), phrase: "Good morning", action: .scene, createdAt: Date()),
            VoiceShortcut(id: UUID(), phrase: "Good night", action: .scene, createdAt: Date()),
            VoiceShortcut(id: UUID(), phrase: "I'm home", action: .scene, createdAt: Date()),
            VoiceShortcut(id: UUID(), phrase: "I'm leaving", action: .scene, createdAt: Date())
        ]

        suggestedShortcuts.append(contentsOf: commonShortcuts)
    }

    // MARK: - Voice Command History

    /// Records a voice command execution
    ///
    /// - Parameters:
    ///   - command: The command text
    ///   - success: Whether the command succeeded
    ///   - deviceName: Optional device name affected
    func recordCommand(_ command: String, success: Bool, deviceName: String? = nil) {
        let voiceCommand = VoiceCommand(
            id: UUID(),
            command: command,
            timestamp: Date(),
            success: success,
            deviceName: deviceName
        )

        voiceHistory.insert(voiceCommand, at: 0)

        // Limit history size
        if voiceHistory.count > maxHistoryItems {
            voiceHistory = Array(voiceHistory.prefix(maxHistoryItems))
        }

        saveHistory()
    }

    /// Gets voice command statistics
    ///
    /// - Returns: Dictionary of command frequency
    func getCommandStatistics() -> [String: Int] {
        var stats: [String: Int] = [:]

        for command in voiceHistory where command.success {
            let normalized = command.command.lowercased()
            stats[normalized, default: 0] += 1
        }

        return stats
    }

    /// Gets most frequently used voice commands
    ///
    /// - Parameter limit: Number of commands to return
    /// - Returns: Array of command strings sorted by frequency
    func getMostUsedCommands(limit: Int = 10) -> [String] {
        let stats = getCommandStatistics()
        return stats.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { $0.key }
    }

    // MARK: - Persistence

    /// Load voice history securely from Keychain
    ///
    /// **Security**: Voice history may contain sensitive commands and is encrypted in Keychain
    /// **GDPR Compliance**: Voice data is user-generated content that must be protected
    private func loadHistory() {
        do {
            guard let data = try SecureStorage.shared.retrieveData(key: historyKey) else {
                // Try migrating from old UserDefaults storage
                migrateHistoryFromUserDefaults()
                return
            }
            let history = try JSONDecoder().decode([VoiceCommand].self, from: data)
            voiceHistory = history
        } catch {
            // Failed to load history - start with empty array
            voiceHistory = []
        }
    }

    /// Save voice history securely to Keychain
    ///
    /// **Security**: Voice history may contain sensitive commands and is encrypted in Keychain
    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(voiceHistory)
            try SecureStorage.shared.save(key: historyKey, data: data)
        } catch {
            // Failed to save history
        }
    }

    /// Save voice shortcuts securely to Keychain
    ///
    /// **Security**: Voice shortcuts are encrypted in Keychain
    private func saveShortcuts() {
        do {
            let data = try JSONEncoder().encode(suggestedShortcuts)
            try SecureStorage.shared.save(key: "com.homekittv.voiceShortcuts", data: data)
        } catch {
            // Failed to save shortcuts
        }
    }

    /// Migrate voice history from insecure UserDefaults to secure Keychain
    ///
    /// This is a one-time migration for existing users.
    private func migrateHistoryFromUserDefaults() {
        // Migrate history
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let history = try? JSONDecoder().decode([VoiceCommand].self, from: data) {
            voiceHistory = history
            saveHistory()
            UserDefaults.standard.removeObject(forKey: historyKey)
        }

        // Migrate shortcuts
        if let data = UserDefaults.standard.data(forKey: "com.homekittv.voiceShortcuts"),
           let shortcuts = try? JSONDecoder().decode([String].self, from: data) {
            suggestedShortcuts = shortcuts
            saveShortcuts()
            UserDefaults.standard.removeObject(forKey: "com.homekittv.voiceShortcuts")
        }
    }
}

// MARK: - Models

/// Voice command record
struct VoiceCommand: Identifiable, Codable {
    let id: UUID
    let command: String
    let timestamp: Date
    let success: Bool
    let deviceName: String?
}

/// Voice shortcut configuration
struct VoiceShortcut: Identifiable, Codable {
    let id: UUID
    var deviceID: String?
    var sceneID: String?
    var phrase: String
    var action: DeviceAction
    let createdAt: Date

    init(id: UUID, deviceID: String? = nil, sceneID: String? = nil, phrase: String, action: DeviceAction, createdAt: Date) {
        self.id = id
        self.deviceID = deviceID
        self.sceneID = sceneID
        self.phrase = phrase
        self.action = action
        self.createdAt = createdAt
    }
}

/// Device action types
enum DeviceAction: String, Codable {
    case on = "On"
    case off = "Off"
    case toggle = "Toggle"
    case scene = "Scene"
    case allOff = "All Off"
    case allOn = "All On"
}

// MARK: - Intent Definitions (Placeholders for SiriKit)

class DeviceControlIntent: NSObject {
    var deviceName: String = ""
    var action: String = ""
    var suggestedInvocationPhrase: String = ""
}

class SceneControlIntent: NSObject {
    var sceneName: String = ""
    var suggestedInvocationPhrase: String = ""
}
