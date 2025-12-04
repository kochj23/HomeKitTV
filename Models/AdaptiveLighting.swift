import Foundation
import HomeKit

/// Adaptive lighting manager
///
/// Manages automatic color temperature adjustment throughout the day
/// to match natural circadian rhythms.
///
/// Features:
/// - Sunrise/sunset synchronization
/// - Circadian rhythm support
/// - Per-room configuration
/// - Manual override
class AdaptiveLightingManager: ObservableObject {
    static let shared = AdaptiveLightingManager()

    @Published var isEnabled: Bool = false
    @Published var lightProfiles: [LightProfile] = []
    @Published var overrides: [String: ColorTemperatureOverride] = [:]

    private let profilesKey = "com.homekittv.adaptiveLighting"

    private init() {
        loadProfiles()
    }

    // MARK: - Color Temperature Calculation

    /// Calculate color temperature for current time
    func calculateColorTemperature(for time: Date = Date()) -> Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let totalMinutes = hour * 60 + minute

        // Sunrise: 6:00 AM (360 minutes)
        // Noon: 12:00 PM (720 minutes)
        // Sunset: 8:00 PM (1200 minutes)
        // Night: 10:00 PM (1320 minutes)

        let sunriseMinutes = 360.0  // 6:00 AM
        let noonMinutes = 720.0     // 12:00 PM
        let sunsetMinutes = 1200.0  // 8:00 PM
        let nightMinutes = 1320.0   // 10:00 PM

        let currentMinutes = Double(totalMinutes)

        // Color temperatures (in mireds)
        let nightTemp = 500     // Warm white (2000K)
        let morningTemp = 350   // Soft white (2857K)
        let dayTemp = 140       // Cool white (7142K)
        let eveningTemp = 400   // Warm white (2500K)

        var colorTemp: Double

        if currentMinutes < sunriseMinutes {
            // Night to sunrise (warm)
            colorTemp = Double(nightTemp)
        } else if currentMinutes < noonMinutes {
            // Sunrise to noon (warming to cool)
            let progress = (currentMinutes - sunriseMinutes) / (noonMinutes - sunriseMinutes)
            colorTemp = Double(morningTemp) - (Double(morningTemp - dayTemp) * progress)
        } else if currentMinutes < sunsetMinutes {
            // Noon to sunset (stay cool)
            colorTemp = Double(dayTemp)
        } else if currentMinutes < nightMinutes {
            // Sunset to night (cooling to warm)
            let progress = (currentMinutes - sunsetMinutes) / (nightMinutes - sunsetMinutes)
            colorTemp = Double(dayTemp) + (Double(eveningTemp - dayTemp) * progress)
        } else {
            // After 10 PM (very warm)
            colorTemp = Double(nightTemp)
        }

        return Int(colorTemp)
    }

    /// Apply adaptive lighting to all compatible lights
    func applyToAllLights(homeManager: HomeKitManager) {
        let colorTemp = calculateColorTemperature()

        let compatibleLights = homeManager.accessories.filter { accessory in
            accessory.services.contains { service in
                service.serviceType == HMServiceTypeLightbulb &&
                service.characteristics.contains { $0.characteristicType == HMCharacteristicTypeColorTemperature }
            }
        }

        for light in compatibleLights {
            // Check for override
            if let override = overrides[light.uniqueIdentifier.uuidString], override.isActive {
                continue
            }

            if let service = light.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }),
               let tempChar = service.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeColorTemperature }) {
                homeManager.setColorTemperature(tempChar, value: colorTemp) { _ in }
            }
        }
    }

    /// Set override for specific light
    func setOverride(for accessory: HMAccessory, temperature: Int, duration: TimeInterval) {
        overrides[accessory.uniqueIdentifier.uuidString] = ColorTemperatureOverride(
            temperature: temperature,
            expiresAt: Date().addingTimeInterval(duration)
        )
    }

    /// Clear override for specific light
    func clearOverride(for accessory: HMAccessory) {
        overrides.removeValue(forKey: accessory.uniqueIdentifier.uuidString)
    }

    /// Check if override is active and clear if expired
    func isOverrideActive(for accessory: HMAccessory) -> Bool {
        guard let override = overrides[accessory.uniqueIdentifier.uuidString] else { return false }

        if override.expiresAt < Date() {
            clearOverride(for: accessory)
            return false
        }

        return true
    }

    // MARK: - Persistence

    private func loadProfiles() {
        if let data = UserDefaults.standard.data(forKey: profilesKey),
           let profiles = try? JSONDecoder().decode([LightProfile].self, from: data) {
            lightProfiles = profiles
        }
    }

    private func saveProfiles() {
        if let data = try? JSONEncoder().encode(lightProfiles) {
            UserDefaults.standard.set(data, forKey: profilesKey)
        }
    }
}

// MARK: - Models

/// Light profile for adaptive lighting
struct LightProfile: Identifiable, Codable {
    let id: UUID
    let accessoryID: String
    var enabled: Bool
    var customSchedule: ColorTemperatureSchedule?

    init(accessoryID: String, enabled: Bool = true, customSchedule: ColorTemperatureSchedule? = nil) {
        self.id = UUID()
        self.accessoryID = accessoryID
        self.enabled = enabled
        self.customSchedule = customSchedule
    }
}

/// Color temperature schedule
struct ColorTemperatureSchedule: Codable {
    var sunriseTemp: Int
    var noonTemp: Int
    var sunsetTemp: Int
    var nightTemp: Int

    static let `default` = ColorTemperatureSchedule(
        sunriseTemp: 350,  // 2857K
        noonTemp: 140,     // 7142K
        sunsetTemp: 400,   // 2500K
        nightTemp: 500     // 2000K
    )
}

/// Temporary color temperature override
struct ColorTemperatureOverride {
    let temperature: Int
    let expiresAt: Date

    var isActive: Bool {
        expiresAt > Date()
    }
}
