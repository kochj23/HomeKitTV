import Foundation
import HomeKit

/// Family controls manager
///
/// Provides:
/// - Kid-friendly mode with limited controls
/// - Bedtime automation enforcement
/// - Screen time integration concepts
/// - Allowance-based scene execution
class FamilyControlsManager: ObservableObject {
    static let shared = FamilyControlsManager()

    @Published var kidMode: KidMode?
    @Published var bedtimeSchedule: BedtimeSchedule?
    @Published var allowedAccessories: Set<String> = []
    @Published var allowedScenes: Set<String> = []
    @Published var isKidModeActive = false

    private let kidModeKey = "com.homekittv.kidMode"
    private let bedtimeKey = "com.homekittv.bedtimeSchedule"

    private init() {
        loadSettings()
    }

    // MARK: - Kid Mode

    /// Enable kid mode
    func enableKidMode() {
        isKidModeActive = true
    }

    /// Disable kid mode
    func disableKidMode() {
        isKidModeActive = false
    }

    /// Check if accessory is allowed in kid mode
    func isAllowed(_ accessory: HMAccessory) -> Bool {
        guard isKidModeActive else { return true }
        return allowedAccessories.contains(accessory.uniqueIdentifier.uuidString)
    }

    /// Check if scene is allowed in kid mode
    func isAllowed(_ scene: HMActionSet) -> Bool {
        guard isKidModeActive else { return true }
        return allowedScenes.contains(scene.uniqueIdentifier.uuidString)
    }

    /// Toggle accessory permission in kid mode
    func toggleAccessoryPermission(_ accessory: HMAccessory) {
        let id = accessory.uniqueIdentifier.uuidString
        if allowedAccessories.contains(id) {
            allowedAccessories.remove(id)
        } else {
            allowedAccessories.insert(id)
        }
        saveSettings()
    }

    /// Toggle scene permission in kid mode
    func toggleScenePermission(_ scene: HMActionSet) {
        let id = scene.uniqueIdentifier.uuidString
        if allowedScenes.contains(id) {
            allowedScenes.remove(id)
        } else {
            allowedScenes.insert(id)
        }
        saveSettings()
    }

    // MARK: - Bedtime Enforcement

    /// Check if bedtime is active
    func isBedtimeActive() -> Bool {
        guard let schedule = bedtimeSchedule else { return false }
        guard schedule.enabled else { return false }

        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let currentMinutes = hour * 60 + minute

        let bedtimeHour = calendar.component(.hour, from: schedule.bedtime)
        let bedtimeMinute = calendar.component(.minute, from: schedule.bedtime)
        let bedtimeMinutes = bedtimeHour * 60 + bedtimeMinute

        let wakeHour = calendar.component(.hour, from: schedule.wakeTime)
        let wakeMinute = calendar.component(.minute, from: schedule.wakeTime)
        let wakeMinutes = wakeHour * 60 + wakeMinute

        if bedtimeMinutes < wakeMinutes {
            // Same day bedtime
            return currentMinutes >= bedtimeMinutes && currentMinutes < wakeMinutes
        } else {
            // Crosses midnight
            return currentMinutes >= bedtimeMinutes || currentMinutes < wakeMinutes
        }
    }

    /// Get bedtime message
    func getBedtimeMessage() -> String? {
        guard isBedtimeActive(), let schedule = bedtimeSchedule else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "Bedtime mode active until \(formatter.string(from: schedule.wakeTime))"
    }

    /// Enforce bedtime rules
    func enforceBedtime(homeManager: HomeKitManager) {
        guard let schedule = bedtimeSchedule, schedule.enabled else { return }

        if isBedtimeActive() {
            // Execute bedtime actions
            if schedule.turnOffLights {
                let lights = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLightbulb } }
                for light in lights where homeManager.getPowerState(light) {
                    homeManager.toggleAccessory(light)
                }
            }

            if schedule.lockDoors {
                let locks = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLockMechanism } }
                for lock in locks {
                    if let service = lock.services.first(where: { $0.serviceType == HMServiceTypeLockMechanism }) {
                        homeManager.setLockState(service, locked: true) { _ in }
                    }
                }
            }

            if schedule.adjustThermostat, let targetTemp = schedule.nightTemperature {
                let thermostats = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeThermostat } }
                for thermostat in thermostats {
                    if let service = thermostat.services.first(where: { $0.serviceType == HMServiceTypeThermostat }) {
                        homeManager.setTargetTemperature(service, temperature: Double(targetTemp)) { _ in }
                    }
                }
            }
        }
    }

    // MARK: - Persistence

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: kidModeKey),
           let kidMode = try? JSONDecoder().decode(KidMode.self, from: data) {
            self.kidMode = kidMode
            self.allowedAccessories = kidMode.allowedAccessories
            self.allowedScenes = kidMode.allowedScenes
        }

        if let data = UserDefaults.standard.data(forKey: bedtimeKey),
           let schedule = try? JSONDecoder().decode(BedtimeSchedule.self, from: data) {
            self.bedtimeSchedule = schedule
        }
    }

    private func saveSettings() {
        if let kidMode = kidMode {
            if let data = try? JSONEncoder().encode(kidMode) {
                UserDefaults.standard.set(data, forKey: kidModeKey)
            }
        }

        if let schedule = bedtimeSchedule {
            if let data = try? JSONEncoder().encode(schedule) {
                UserDefaults.standard.set(data, forKey: bedtimeKey)
            }
        }
    }
}

// MARK: - Models

/// Kid mode configuration
struct KidMode: Codable {
    var enabled: Bool
    var allowedAccessories: Set<String>
    var allowedScenes: Set<String>
    var restrictedRooms: Set<String>
    var allowSceneExecution: Bool
    var allowAutomationControl: Bool
}

/// Bedtime schedule configuration
struct BedtimeSchedule: Codable {
    var enabled: Bool
    var bedtime: Date
    var wakeTime: Date
    var turnOffLights: Bool
    var lockDoors: Bool
    var adjustThermostat: Bool
    var nightTemperature: Int?
    var enabledDays: Set<Int> // 1-7 for weekdays
}
