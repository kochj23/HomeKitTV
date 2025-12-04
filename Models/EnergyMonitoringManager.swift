import Foundation
import HomeKit

/// Energy monitoring and power tracking manager
///
/// Tracks power consumption, estimates costs, and provides energy-saving recommendations.
///
/// **Features**:
/// - Real-time power consumption tracking
/// - Historical usage trends (daily/weekly/monthly)
/// - Cost estimation based on utility rates
/// - Device-by-device power breakdown
/// - Smart energy-saving suggestions
/// - Peak usage alerts
class EnergyMonitoringManager: ObservableObject {
    static let shared = EnergyMonitoringManager()

    @Published var currentPowerUsage: Double = 0.0  // kW
    @Published var dailyUsage: [Date: Double] = [:]
    @Published var devicePowerUsage: [String: Double] = [:]
    @Published var costPerKWh: Double = 0.15  // Default rate
    @Published var energySavings: [EnergySaving] = []

    private let usageKey = "com.homekittv.energyUsage"
    private var updateTimer: Timer?

    private init() {
        loadUsageData()
        startMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updatePowerUsage()
        }
    }

    func updatePowerUsage() {
        // Simulate power usage calculation
        currentPowerUsage = devicePowerUsage.values.reduce(0, +)

        let today = Calendar.current.startOfDay(for: Date())
        dailyUsage[today, default: 0] += currentPowerUsage / 60.0  // Convert to kWh

        saveUsageData()
        analyzePowerUsage()
    }

    // MARK: - Cost Calculation

    func getDailyCost() -> Double {
        let today = Calendar.current.startOfDay(for: Date())
        return (dailyUsage[today] ?? 0) * costPerKWh
    }

    func getWeeklyCost() -> Double {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        return dailyUsage
            .filter { $0.key >= weekAgo }
            .values
            .reduce(0, +) * costPerKWh
    }

    func getMonthlyCost() -> Double {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!

        return dailyUsage
            .filter { $0.key >= monthAgo }
            .values
            .reduce(0, +) * costPerKWh
    }

    // MARK: - Analytics

    func analyzePowerUsage() {
        energySavings.removeAll()

        // Find high-consumption devices
        for (deviceID, power) in devicePowerUsage where power > 1.0 {
            energySavings.append(EnergySaving(
                deviceID: deviceID,
                suggestion: "Device using \(String(format: "%.2f", power))kW - consider turning off when not in use",
                potentialSavings: power * 24 * costPerKWh
            ))
        }

        // Check for peak usage times
        if currentPowerUsage > 5.0 {
            energySavings.append(EnergySaving(
                deviceID: "system",
                suggestion: "High power usage detected - \(String(format: "%.2f", currentPowerUsage))kW",
                potentialSavings: (currentPowerUsage - 3.0) * 24 * costPerKWh
            ))
        }
    }

    func getUsageTrend(days: Int) -> [UsageDataPoint] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date())!

        return dailyUsage
            .filter { $0.key >= startDate }
            .sorted { $0.key < $1.key }
            .map { UsageDataPoint(date: $0.key, usage: $0.value) }
    }

    // MARK: - Device Tracking

    func trackDevice(_ deviceID: String, power: Double) {
        devicePowerUsage[deviceID] = power
    }

    func removeDevice(_ deviceID: String) {
        devicePowerUsage.removeValue(forKey: deviceID)
    }

    // MARK: - Persistence

    private func loadUsageData() {
        if let data = UserDefaults.standard.data(forKey: usageKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            // Convert string keys back to dates
            for (key, value) in decoded {
                if let timestamp = Double(key) {
                    let date = Date(timeIntervalSince1970: timestamp)
                    dailyUsage[date] = value
                }
            }
        }
    }

    private func saveUsageData() {
        // Convert date keys to strings for JSON encoding
        let encoded = dailyUsage.reduce(into: [String: Double]()) { result, pair in
            result[String(pair.key.timeIntervalSince1970)] = pair.value
        }

        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: usageKey)
        }
    }
}

// MARK: - Models

struct EnergySaving: Identifiable {
    let id = UUID()
    let deviceID: String
    let suggestion: String
    let potentialSavings: Double  // Daily savings in currency
}

struct UsageDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let usage: Double  // kWh
}
