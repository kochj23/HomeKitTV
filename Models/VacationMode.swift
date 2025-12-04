import Foundation
import HomeKit

/// Vacation mode manager
///
/// Provides presence simulation and energy savings while away:
/// - Randomize light schedules
/// - Adjust thermostat for savings
/// - Security monitoring increase
/// - Plant watering schedules
class VacationModeManager: ObservableObject {
    static let shared = VacationModeManager()

    @Published var isActive: Bool = false
    @Published var vacationSettings: VacationSettings?
    @Published var lightSchedule: [VacationLightSchedule] = []

    private let settingsKey = "com.homekittv.vacationMode"

    private init() {
        loadSettings()
    }

    // MARK: - Vacation Mode Control

    /// Activate vacation mode
    func activateVacationMode(startDate: Date, endDate: Date, homeManager: HomeKitManager) {
        isActive = true

        vacationSettings = VacationSettings(
            startDate: startDate,
            endDate: endDate,
            randomizeLights: true,
            adjustThermostat: true,
            targetTemperature: 60,
            lockDoors: true,
            increaseCameraRecording: true
        )

        // Generate random light schedule
        generateLightSchedule(homeManager: homeManager)

        // Adjust thermostats
        if vacationSettings!.adjustThermostat {
            adjustThermostats(homeManager: homeManager, temperature: vacationSettings!.targetTemperature)
        }

        // Lock all doors
        if vacationSettings!.lockDoors {
            lockAllDoors(homeManager: homeManager)
        }

        saveSettings()
    }

    /// Deactivate vacation mode
    func deactivateVacationMode(homeManager: HomeKitManager) {
        isActive = false
        lightSchedule.removeAll()
        saveSettings()
    }

    // MARK: - Light Randomization

    /// Generate random light schedule to simulate presence
    func generateLightSchedule(homeManager: HomeKitManager) {
        lightSchedule.removeAll()

        let lights = homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }

        // Create random on/off times for each light
        for light in lights {
            let onTime = randomTime(between: 17, and: 21) // 5 PM - 9 PM
            let offTime = randomTime(between: 22, and: 24) // 10 PM - midnight

            lightSchedule.append(VacationLightSchedule(
                accessoryID: light.uniqueIdentifier.uuidString,
                accessoryName: light.name,
                onTime: onTime,
                offTime: offTime,
                randomVariation: 30 // +/- 30 minutes
            ))
        }

        saveSettings()
    }

    /// Execute vacation light schedule for current time
    func executeSchedule(homeManager: HomeKitManager) {
        guard isActive else { return }

        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute

        for schedule in lightSchedule {
            let onMinutes = schedule.onTime.hour * 60 + schedule.onTime.minute
            let offMinutes = schedule.offTime.hour * 60 + schedule.offTime.minute

            // Add random variation (+/- 30 minutes)
            let variation = Int.random(in: -schedule.randomVariation...schedule.randomVariation)
            let adjustedOn = onMinutes + variation
            let adjustedOff = offMinutes + variation

            if let accessory = homeManager.accessories.first(where: { $0.uniqueIdentifier.uuidString == schedule.accessoryID }) {
                let shouldBeOn = currentMinutes >= adjustedOn && currentMinutes < adjustedOff
                let isOn = homeManager.getPowerState(accessory)

                if shouldBeOn != isOn {
                    homeManager.toggleAccessory(accessory)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func randomTime(between startHour: Int, and endHour: Int) -> (hour: Int, minute: Int) {
        let hour = Int.random(in: startHour...endHour)
        let minute = Int.random(in: 0...59)
        return (hour, minute)
    }

    private func adjustThermostats(homeManager: HomeKitManager, temperature: Int) {
        let thermostats = homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeThermostat }
        }

        for thermostat in thermostats {
            if let service = thermostat.services.first(where: { $0.serviceType == HMServiceTypeThermostat }) {
                homeManager.setTargetTemperature(service, temperature: Double(temperature)) { _ in }
            }
        }
    }

    private func lockAllDoors(homeManager: HomeKitManager) {
        let locks = homeManager.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLockMechanism }
        }

        for lock in locks {
            if let service = lock.services.first(where: { $0.serviceType == HMServiceTypeLockMechanism }) {
                homeManager.setLockState(service, locked: true) { _ in }
            }
        }
    }

    // MARK: - Persistence

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(VacationSettings.self, from: data) {
            vacationSettings = settings

            // Check if vacation is still active
            if settings.endDate < Date() {
                isActive = false
            } else {
                isActive = true
            }
        }
    }

    private func saveSettings() {
        if let settings = vacationSettings {
            if let data = try? JSONEncoder().encode(settings) {
                UserDefaults.standard.set(data, forKey: settingsKey)
            }
        }
    }
}

// MARK: - Models

/// Vacation mode settings
struct VacationSettings: Codable {
    var startDate: Date
    var endDate: Date
    var randomizeLights: Bool
    var adjustThermostat: Bool
    var targetTemperature: Int
    var lockDoors: Bool
    var increaseCameraRecording: Bool
}

/// Vacation light schedule
struct VacationLightSchedule: Codable {
    let accessoryID: String
    let accessoryName: String
    var onTime: (hour: Int, minute: Int)
    var offTime: (hour: Int, minute: Int)
    var randomVariation: Int // minutes of random variation
}

// Make tuple Codable
extension VacationLightSchedule {
    enum CodingKeys: String, CodingKey {
        case accessoryID, accessoryName, onHour, onMinute, offHour, offMinute, randomVariation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessoryID = try container.decode(String.self, forKey: .accessoryID)
        accessoryName = try container.decode(String.self, forKey: .accessoryName)
        let onH = try container.decode(Int.self, forKey: .onHour)
        let onM = try container.decode(Int.self, forKey: .onMinute)
        onTime = (hour: onH, minute: onM)
        let offH = try container.decode(Int.self, forKey: .offHour)
        let offM = try container.decode(Int.self, forKey: .offMinute)
        offTime = (hour: offH, minute: offM)
        randomVariation = try container.decode(Int.self, forKey: .randomVariation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessoryID, forKey: .accessoryID)
        try container.encode(accessoryName, forKey: .accessoryName)
        try container.encode(onTime.hour, forKey: .onHour)
        try container.encode(onTime.minute, forKey: .onMinute)
        try container.encode(offTime.hour, forKey: .offHour)
        try container.encode(offTime.minute, forKey: .offMinute)
        try container.encode(randomVariation, forKey: .randomVariation)
    }
}
