import Foundation
import HomeKit
import CoreLocation

/// Advanced automation manager
///
/// Handles sophisticated automation types:
/// - Geofencing (home/away detection)
/// - Sunrise/sunset triggers
/// - Occupancy-based controls
/// - Weather-triggered actions
class AdvancedAutomationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = AdvancedAutomationManager()

    @Published var geofences: [GeofenceAutomation] = []
    @Published var sunriseSunsetAutomations: [SunriseSunsetAutomation] = []
    @Published var occupancyRules: [OccupancyRule] = []
    @Published var weatherAutomations: [WeatherAutomation] = []
    @Published var isAtHome: Bool = true
    @Published var lastLocationUpdate: Date?

    private let locationManager = CLLocationManager()
    private let geofencesKey = "com.homekittv.geofences"
    private let sunriseSunsetKey = "com.homekittv.sunriseSunset"
    private let occupancyKey = "com.homekittv.occupancy"
    private let weatherKey = "com.homekittv.weatherAutomations"

    private override init() {
        super.init()
        locationManager.delegate = self
        loadAutomations()
    }

    // MARK: - Geofencing

    /// Request location authorization
    func setupGeofencing() {
        locationManager.requestAlwaysAuthorization()
        locationManager.startMonitoringSignificantLocationChanges()
    }

    /// Create geofence automation
    func createGeofence(
        name: String,
        centerLat: Double,
        centerLon: Double,
        radiusMeters: Double,
        arriveActions: [AutomationAction],
        departActions: [AutomationAction]
    ) {
        let geofence = GeofenceAutomation(
            name: name,
            centerLatitude: centerLat,
            centerLongitude: centerLon,
            radiusMeters: radiusMeters,
            arriveActions: arriveActions,
            departActions: departActions
        )
        geofences.append(geofence)
        saveGeofences()

        // Setup actual geofencing with CLLocationManager
        let center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
        let region = CLCircularRegion(center: center, radius: radiusMeters, identifier: geofence.id.uuidString)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
    }

    /// Delete geofence
    func deleteGeofence(_ geofence: GeofenceAutomation) {
        geofences.removeAll { $0.id == geofence.id }
        saveGeofences()

        // Stop monitoring
        if let region = locationManager.monitoredRegions.first(where: { $0.identifier == geofence.id.uuidString }) {
            locationManager.stopMonitoring(for: region)
        }
    }

    // CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let geofence = geofences.first(where: { $0.id.uuidString == region.identifier }) {
            isAtHome = true
            lastLocationUpdate = Date()
            // Execute arrive actions
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if let geofence = geofences.first(where: { $0.id.uuidString == region.identifier }) {
            isAtHome = false
            lastLocationUpdate = Date()
            // Execute depart actions
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocationUpdate = Date()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

    // MARK: - Sunrise/Sunset

    /// Create sunrise/sunset automation
    func createSunriseSunsetAutomation(
        name: String,
        trigger: SunriseSunsetTrigger,
        offset: TimeInterval,
        actions: [AutomationAction]
    ) {
        let automation = SunriseSunsetAutomation(
            name: name,
            trigger: trigger,
            offsetMinutes: Int(offset / 60),
            actions: actions
        )
        sunriseSunsetAutomations.append(automation)
        saveSunriseSunset()
    }

    /// Calculate next sunrise/sunset time
    func nextSunriseTime() -> Date {
        // Would integrate with solar calculation API
        // For now, use 6:30 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 30
        return calendar.date(from: components) ?? Date()
    }

    func nextSunsetTime() -> Date {
        // Would integrate with solar calculation API
        // For now, use 6:30 PM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 30
        return calendar.date(from: components) ?? Date()
    }

    // MARK: - Occupancy

    /// Create occupancy rule
    func createOccupancyRule(
        room: HMRoom,
        timeoutMinutes: Int,
        actions: [AutomationAction]
    ) {
        let rule = OccupancyRule(
            roomID: room.uniqueIdentifier.uuidString,
            roomName: room.name,
            timeoutMinutes: timeoutMinutes,
            actions: actions
        )
        occupancyRules.append(rule)
        saveOccupancy()
    }

    /// Check if room is occupied
    func isRoomOccupied(_ room: HMRoom, homeManager: HomeKitManager) -> Bool {
        let accessories = homeManager.accessories(for: room)

        for accessory in accessories {
            for service in accessory.services {
                if let motionChar = service.characteristics.first(where: {
                    $0.characteristicType == HMCharacteristicTypeMotionDetected
                }) {
                    if (motionChar.value as? Bool) == true {
                        return true
                    }
                }
            }
        }

        return false
    }

    // MARK: - Weather Automations

    /// Create weather-triggered automation
    func createWeatherAutomation(
        name: String,
        condition: WeatherCondition,
        actions: [AutomationAction]
    ) {
        let automation = WeatherAutomation(
            name: name,
            condition: condition,
            actions: actions
        )
        weatherAutomations.append(automation)
        saveWeatherAutomations()
    }

    /// Check weather conditions and trigger automations
    func checkWeatherConditions() {
        guard let weather = IntegrationManager.shared.weather else { return }

        for automation in weatherAutomations where automation.enabled {
            var shouldTrigger = false

            switch automation.condition {
            case .temperatureAbove(let temp):
                shouldTrigger = weather.temperature > temp
            case .temperatureBelow(let temp):
                shouldTrigger = weather.temperature < temp
            case .humidityAbove(let humidity):
                shouldTrigger = weather.humidity > humidity
            case .condition(let conditionName):
                shouldTrigger = weather.condition.localizedCaseInsensitiveContains(conditionName)
            }

            if shouldTrigger && !automation.lastTriggered.isToday {
                // Execute actions
                // Mark as triggered today
            }
        }
    }

    // MARK: - Persistence

    private func loadAutomations() {
        if let data = UserDefaults.standard.data(forKey: geofencesKey),
           let geofences = try? JSONDecoder().decode([GeofenceAutomation].self, from: data) {
            self.geofences = geofences
        }

        if let data = UserDefaults.standard.data(forKey: sunriseSunsetKey),
           let automations = try? JSONDecoder().decode([SunriseSunsetAutomation].self, from: data) {
            self.sunriseSunsetAutomations = automations
        }

        if let data = UserDefaults.standard.data(forKey: occupancyKey),
           let rules = try? JSONDecoder().decode([OccupancyRule].self, from: data) {
            self.occupancyRules = rules
        }

        if let data = UserDefaults.standard.data(forKey: weatherKey),
           let automations = try? JSONDecoder().decode([WeatherAutomation].self, from: data) {
            self.weatherAutomations = automations
        }
    }

    private func saveGeofences() {
        if let data = try? JSONEncoder().encode(geofences) {
            UserDefaults.standard.set(data, forKey: geofencesKey)
        }
    }

    private func saveSunriseSunset() {
        if let data = try? JSONEncoder().encode(sunriseSunsetAutomations) {
            UserDefaults.standard.set(data, forKey: sunriseSunsetKey)
        }
    }

    private func saveOccupancy() {
        if let data = try? JSONEncoder().encode(occupancyRules) {
            UserDefaults.standard.set(data, forKey: occupancyKey)
        }
    }

    private func saveWeatherAutomations() {
        if let data = try? JSONEncoder().encode(weatherAutomations) {
            UserDefaults.standard.set(data, forKey: weatherKey)
        }
    }
}

// MARK: - Models

/// Geofence automation
struct GeofenceAutomation: Identifiable, Codable {
    let id: UUID
    var name: String
    var centerLatitude: Double
    var centerLongitude: Double
    var radiusMeters: Double
    var arriveActions: [AutomationAction]
    var departActions: [AutomationAction]
    var enabled: Bool

    init(name: String, centerLatitude: Double, centerLongitude: Double, radiusMeters: Double, arriveActions: [AutomationAction], departActions: [AutomationAction], enabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.centerLatitude = centerLatitude
        self.centerLongitude = centerLongitude
        self.radiusMeters = radiusMeters
        self.arriveActions = arriveActions
        self.departActions = departActions
        self.enabled = enabled
    }
}

/// Sunrise/sunset automation
struct SunriseSunsetAutomation: Identifiable, Codable {
    let id: UUID
    var name: String
    var trigger: SunriseSunsetTrigger
    var offsetMinutes: Int
    var actions: [AutomationAction]
    var enabled: Bool

    init(name: String, trigger: SunriseSunsetTrigger, offsetMinutes: Int, actions: [AutomationAction], enabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.trigger = trigger
        self.offsetMinutes = offsetMinutes
        self.actions = actions
        self.enabled = enabled
    }
}

/// Sunrise/sunset trigger types
enum SunriseSunsetTrigger: String, Codable {
    case sunrise = "Sunrise"
    case sunset = "Sunset"
    case civilTwilight = "Civil Twilight"
    case nauticalTwilight = "Nautical Twilight"
}

/// Occupancy rule
struct OccupancyRule: Identifiable, Codable {
    let id: UUID
    var roomID: String
    var roomName: String
    var timeoutMinutes: Int
    var actions: [AutomationAction]
    var enabled: Bool

    init(roomID: String, roomName: String, timeoutMinutes: Int, actions: [AutomationAction], enabled: Bool = true) {
        self.id = UUID()
        self.roomID = roomID
        self.roomName = roomName
        self.timeoutMinutes = timeoutMinutes
        self.actions = actions
        self.enabled = enabled
    }
}

/// Weather automation
struct WeatherAutomation: Identifiable, Codable {
    let id: UUID
    var name: String
    var condition: WeatherCondition
    var actions: [AutomationAction]
    var enabled: Bool
    var lastTriggered: Date

    init(name: String, condition: WeatherCondition, actions: [AutomationAction], enabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.condition = condition
        self.actions = actions
        self.enabled = enabled
        self.lastTriggered = Date.distantPast
    }
}

// Extension for Date
extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
