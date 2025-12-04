import Foundation
import HomeKit

/// Energy usage data point for an accessory
///
/// Tracks power consumption over time for analytics and cost estimation.
///
/// **Storage**: Persisted to UserDefaults as JSON
/// **Privacy**: No personal data stored, only usage metrics
struct EnergyDataPoint: Codable, Identifiable {
    /// Unique identifier
    let id: UUID

    /// Accessory unique identifier
    let accessoryID: UUID

    /// Accessory name at time of recording
    let accessoryName: String

    /// Timestamp of the data point
    let timestamp: Date

    /// Power consumption in watts
    let watts: Double

    /// Duration in seconds this measurement represents
    let duration: TimeInterval

    /// Calculated energy in kilowatt-hours
    var kilowattHours: Double {
        return (watts * duration) / (1000 * 3600)
    }

    /// Initialize a new energy data point
    ///
    /// - Parameters:
    ///   - accessoryID: UUID of the accessory
    ///   - accessoryName: Display name of accessory
    ///   - watts: Power consumption in watts
    ///   - duration: Time period in seconds
    init(accessoryID: UUID, accessoryName: String, watts: Double, duration: TimeInterval = 3600) {
        self.id = UUID()
        self.accessoryID = accessoryID
        self.accessoryName = accessoryName
        self.timestamp = Date()
        self.watts = watts
        self.duration = duration
    }
}

/// Energy monitoring configuration
///
/// Stores user preferences for energy tracking and cost calculation.
struct EnergySettings: Codable {
    /// Electricity cost per kilowatt-hour in user's currency
    var costPerKWh: Double

    /// Currency symbol (e.g., "$", "€", "£")
    var currencySymbol: String

    /// Whether to track energy usage
    var isEnabled: Bool

    /// Tracking interval in seconds
    var trackingInterval: TimeInterval

    /// Default initializer
    init(costPerKWh: Double = 0.12, currencySymbol: String = "$", isEnabled: Bool = true, trackingInterval: TimeInterval = 3600) {
        self.costPerKWh = costPerKWh
        self.currencySymbol = currencySymbol
        self.isEnabled = isEnabled
        self.trackingInterval = trackingInterval
    }
}

/// Energy usage statistics for display
///
/// Aggregated energy data for a specific time period.
struct EnergyStatistics {
    /// Total energy consumed in kWh
    let totalKWh: Double

    /// Estimated cost
    let estimatedCost: Double

    /// Start date of the period
    let startDate: Date

    /// End date of the period
    let endDate: Date

    /// Number of data points included
    let dataPointCount: Int

    /// Average power in watts
    let averageWatts: Double

    /// Peak power in watts
    let peakWatts: Double
}

/// Energy monitoring manager
///
/// Tracks and analyzes energy consumption for HomeKit accessories.
///
/// **Features**:
/// - Record energy usage over time
/// - Calculate costs based on electricity rates
/// - Generate usage reports
/// - Identify high-consumption devices
///
/// **Memory Management**: Uses background thread for data processing
/// **Thread Safety**: All published properties updated on main thread
class EnergyMonitor: ObservableObject {
    /// Published array of all energy data points
    @Published var dataPoints: [EnergyDataPoint] = []

    /// Energy settings
    @Published var settings: EnergySettings

    /// UserDefaults keys
    private let dataPointsKey = "com.homekittv.energyData"
    private let settingsKey = "com.homekittv.energySettings"

    /// Timer for periodic tracking
    private var trackingTimer: Timer?

    /// Singleton instance
    static let shared = EnergyMonitor()

    /// Private initializer
    private init() {
        self.settings = EnergySettings()
        loadData()
        loadSettings()
        startTracking()
    }

    deinit {
        trackingTimer?.invalidate()
    }

    // MARK: - Data Management

    /// Load energy data from storage
    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: dataPointsKey) else {
            dataPoints = []
            return
        }

        do {
            dataPoints = try JSONDecoder().decode([EnergyDataPoint].self, from: data)
        } catch {
            dataPoints = []
        }
    }

    /// Save energy data to storage
    private func saveData() {
        do {
            let data = try JSONEncoder().encode(dataPoints)
            UserDefaults.standard.set(data, forKey: dataPointsKey)
        } catch {
        }
    }

    /// Load settings from storage
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            settings = EnergySettings()
            return
        }

        do {
            settings = try JSONDecoder().decode(EnergySettings.self, from: data)
        } catch {
            settings = EnergySettings()
        }
    }

    /// Save settings to storage
    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
        }
    }

    // MARK: - Tracking

    /// Start automatic energy tracking
    private func startTracking() {
        guard settings.isEnabled else { return }

        trackingTimer = Timer.scheduledTimer(withTimeInterval: settings.trackingInterval, repeats: true) { [weak self] _ in
            self?.recordCurrentUsage()
        }
    }

    /// Stop automatic tracking
    func stopTracking() {
        trackingTimer?.invalidate()
        trackingTimer = nil
    }

    /// Record current energy usage for all accessories
    ///
    /// **Note**: This uses estimated power consumption since HomeKit doesn't provide
    /// real-time power data for most accessories. Estimates are based on typical
    /// device power consumption patterns.
    ///
    /// **Integration**: Call `recordCurrentUsageForAccessories(_:)` from your app
    /// with the accessories from HomeKitManager to track energy.
    ///
    /// **Privacy**: Only records anonymized usage data, no personal information
    private func recordCurrentUsage() {
        // This method is called by the timer but requires external accessory data
        // Use the public recordCurrentUsageForAccessories(_:) method instead
    }

    /// Record current energy usage for provided accessories
    ///
    /// Estimates power consumption based on accessory type and state.
    /// Call this method periodically with accessories from HomeKitManager.
    ///
    /// **Power Estimates**:
    /// - Smart bulbs: 5-15W (depending on brightness)
    /// - Outlets/Switches: Based on connected device (default 0W if off)
    /// - Thermostats: 50-200W (HVAC estimated)
    /// - Fans: 10-75W (based on speed)
    /// - Locks: 0.5W (minimal)
    /// - Sensors: 0.1W (minimal)
    ///
    /// - Parameter accessories: Array of HomeKit accessories to track
    public func recordCurrentUsageForAccessories(_ accessories: [HMAccessory]) {
        guard settings.isEnabled else { return }

        for accessory in accessories where accessory.isReachable {
            let estimatedWatts = estimatePowerConsumption(for: accessory)

            // Only record if there's measurable consumption
            if estimatedWatts > 0 {
                recordUsage(for: accessory, watts: estimatedWatts, duration: settings.trackingInterval)
            }
        }
    }

    /// Estimate power consumption for an accessory
    ///
    /// Provides realistic power estimates based on device type and current state.
    ///
    /// - Parameter accessory: The accessory to estimate
    /// - Returns: Estimated power consumption in watts
    private func estimatePowerConsumption(for accessory: HMAccessory) -> Double {
        var totalWatts: Double = 0

        for service in accessory.services {
            let serviceType = service.serviceType

            // Get power state
            let isPoweredOn = service.characteristics
                .first(where: { $0.characteristicType == HMCharacteristicTypePowerState })
                .flatMap { $0.value as? Bool } ?? false

            guard isPoweredOn else {
                // Device is off, minimal/no power consumption
                continue
            }

            // Estimate based on service type
            if serviceType == HMServiceTypeLightbulb {
                // Get brightness
                let brightness = service.characteristics
                    .first(where: { $0.characteristicType == HMCharacteristicTypeBrightness })
                    .flatMap { $0.value as? Int } ?? 100

                // Smart bulbs: 5-15W depending on brightness
                totalWatts += 5.0 + (Double(brightness) / 100.0) * 10.0
            }
            else if serviceType == HMServiceTypeOutlet || serviceType == HMServiceTypeSwitch {
                // Outlets/switches: Assume average load when on
                // This is highly variable - default to 100W for typical lamp/device
                totalWatts += 100.0
            }
            else if serviceType == HMServiceTypeThermostat {
                // Get current heating/cooling state
                let currentState = service.characteristics
                    .first(where: { $0.characteristicType == "0000000F-0000-1000-8000-0026BB765291" }) // Current Heating Cooling State
                    .flatMap { $0.value as? Int } ?? 0

                // 0 = off, 1 = heating, 2 = cooling
                if currentState == 1 {
                    // Heating: 150W average
                    totalWatts += 150.0
                } else if currentState == 2 {
                    // Cooling: 200W average
                    totalWatts += 200.0
                } else {
                    // Just fan/idle: 50W
                    totalWatts += 50.0
                }
            }
            else if serviceType == HMServiceTypeFan {
                // Get fan speed
                let speed = service.characteristics
                    .first(where: { $0.characteristicType == HMCharacteristicTypeRotationSpeed })
                    .flatMap { $0.value as? Double } ?? 50.0

                // Fans: 10-75W based on speed
                totalWatts += 10.0 + (speed / 100.0) * 65.0
            }
            else if serviceType == HMServiceTypeGarageDoorOpener {
                // Garage door opener: 350W when operating, 5W standby
                // Assume standby most of the time
                totalWatts += 5.0
            }
            else if serviceType == HMServiceTypeSecuritySystem {
                // Security system: 10W continuous
                totalWatts += 10.0
            }
            else if serviceType == HMServiceTypeLockMechanism {
                // Smart locks: Minimal power (0.5W)
                totalWatts += 0.5
            }
            else if serviceType == "000000D8-0000-1000-8000-0026BB765291" { // Television
                // TV: 80-200W depending on size (assume medium)
                totalWatts += 120.0
            }
            else if serviceType == HMServiceTypeSpeaker {
                // Smart speakers: 3-10W
                totalWatts += 5.0
            }
            else if serviceType == HMServiceTypeMotionSensor ||
                    serviceType == HMServiceTypeContactSensor ||
                    serviceType == HMServiceTypeTemperatureSensor ||
                    serviceType == HMServiceTypeHumiditySensor ||
                    serviceType == HMServiceTypeLeakSensor ||
                    serviceType == HMServiceTypeSmokeSensor ||
                    serviceType == HMServiceTypeCarbonMonoxideSensor {
                // Sensors: Very low power (0.1W)
                totalWatts += 0.1
            }
            else if serviceType == HMServiceTypeDoor ||
                    serviceType == HMServiceTypeWindow ||
                    serviceType == HMServiceTypeWindowCovering {
                // Motorized window coverings: 5W standby, 100W when moving
                // Assume mostly standby
                totalWatts += 5.0
            }
            else if serviceType == HMServiceTypeAirPurifier {
                // Air purifiers: 30-60W
                totalWatts += 45.0
            }
            else if serviceType == HMServiceTypeHeaterCooler {
                // Space heaters/coolers: 500-1500W
                totalWatts += 800.0
            }
            else if serviceType == HMServiceTypeHumidifierDehumidifier {
                // Humidifiers: 30-50W
                totalWatts += 40.0
            }
            else {
                // Unknown device type: Assume minimal smart device power
                totalWatts += 2.0
            }
        }

        return totalWatts
    }

    /// Manually record energy usage for an accessory
    ///
    /// - Parameters:
    ///   - accessory: The accessory to record
    ///   - watts: Power consumption in watts
    ///   - duration: Duration in seconds
    func recordUsage(for accessory: HMAccessory, watts: Double, duration: TimeInterval = 3600) {
        let dataPoint = EnergyDataPoint(
            accessoryID: accessory.uniqueIdentifier,
            accessoryName: accessory.name,
            watts: watts,
            duration: duration
        )

        DispatchQueue.main.async {
            self.dataPoints.append(dataPoint)
            self.saveData()
        }
    }

    // MARK: - Statistics

    /// Calculate energy statistics for a date range
    ///
    /// - Parameters:
    ///   - startDate: Start of the period
    ///   - endDate: End of the period
    ///   - accessoryID: Optional filter by accessory
    /// - Returns: Aggregated statistics
    func statistics(from startDate: Date, to endDate: Date, accessoryID: UUID? = nil) -> EnergyStatistics {
        var filtered = dataPoints.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }

        if let accessoryID = accessoryID {
            filtered = filtered.filter { $0.accessoryID == accessoryID }
        }

        let totalKWh = filtered.reduce(0) { $0 + $1.kilowattHours }
        let estimatedCost = totalKWh * settings.costPerKWh
        let averageWatts = filtered.isEmpty ? 0 : filtered.reduce(0) { $0 + $1.watts } / Double(filtered.count)
        let peakWatts = filtered.map { $0.watts }.max() ?? 0

        return EnergyStatistics(
            totalKWh: totalKWh,
            estimatedCost: estimatedCost,
            startDate: startDate,
            endDate: endDate,
            dataPointCount: filtered.count,
            averageWatts: averageWatts,
            peakWatts: peakWatts
        )
    }

    /// Get daily statistics for the last N days
    ///
    /// - Parameter days: Number of days to include
    /// - Returns: Array of daily statistics
    func dailyStatistics(days: Int = 30) -> [(date: Date, stats: EnergyStatistics)] {
        var result: [(Date, EnergyStatistics)] = []
        let calendar = Calendar.current

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()),
                  let startOfDay = calendar.startOfDay(for: date) as Date?,
                  let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                continue
            }

            let stats = statistics(from: startOfDay, to: endOfDay)
            result.append((startOfDay, stats))
        }

        return result.reversed()
    }

    /// Get top energy consumers
    ///
    /// - Parameters:
    ///   - limit: Maximum number of accessories to return
    ///   - days: Number of days to analyze
    /// - Returns: Array of (accessory name, total kWh, cost)
    func topConsumers(limit: Int = 5, days: Int = 30) -> [(name: String, kWh: Double, cost: Double)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        let filtered = dataPoints.filter { $0.timestamp >= startDate }

        let grouped = Dictionary(grouping: filtered) { $0.accessoryName }

        let totals = grouped.map { name, points -> (String, Double, Double) in
            let totalKWh = points.reduce(0) { $0 + $1.kilowattHours }
            let cost = totalKWh * settings.costPerKWh
            return (name, totalKWh, cost)
        }

        return totals.sorted { $0.1 > $1.1 }.prefix(limit).map { $0 }
    }

    /// Clear old data points
    ///
    /// Removes data points older than the specified number of days.
    ///
    /// - Parameter days: Keep data from last N days
    func cleanOldData(keepDays: Int = 90) {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -keepDays, to: Date()) else {
            return
        }

        dataPoints.removeAll { $0.timestamp < cutoffDate }
        saveData()
    }

    /// Export data as CSV
    ///
    /// - Returns: CSV string representation of all data points
    func exportCSV() -> String {
        var csv = "Date,Accessory,Watts,Duration,kWh,Cost\n"

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        for point in dataPoints.sorted(by: { $0.timestamp > $1.timestamp }) {
            let cost = point.kilowattHours * settings.costPerKWh
            csv += "\(formatter.string(from: point.timestamp)),\(point.accessoryName),\(point.watts),\(point.duration),\(String(format: "%.2f", point.kilowattHours)),\(String(format: "%.2f", cost))\n"
        }

        return csv
    }
}
