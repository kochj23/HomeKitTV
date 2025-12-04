import SwiftUI
import Charts
import HomeKit

// MARK: - Energy Monitoring Manager (Embedded temporarily until added to Xcode project)

/// Energy monitoring and power tracking manager
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

    func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.updatePowerUsage()
        }
    }

    func updatePowerUsage() {
        currentPowerUsage = devicePowerUsage.values.reduce(0, +)

        let today = Calendar.current.startOfDay(for: Date())
        dailyUsage[today, default: 0] += currentPowerUsage / 60.0

        saveUsageData()
        analyzePowerUsage()
    }

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

    func analyzePowerUsage() {
        energySavings.removeAll()

        for (deviceID, power) in devicePowerUsage where power > 1.0 {
            energySavings.append(EnergySaving(
                deviceID: deviceID,
                suggestion: "Device using \(String(format: "%.2f", power))kW - consider turning off when not in use",
                potentialSavings: power * 24 * costPerKWh
            ))
        }

        if currentPowerUsage > 5.0 {
            energySavings.append(EnergySaving(
                deviceID: "system",
                suggestion: "High power usage detected - \(String(format: "%.2f", currentPowerUsage))kW",
                potentialSavings: (currentPowerUsage - 3.0) * 24 * costPerKWh
            ))
        }
    }

    private func loadUsageData() {
        if let data = UserDefaults.standard.data(forKey: usageKey),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            for (key, value) in decoded {
                if let timestamp = Double(key) {
                    let date = Date(timeIntervalSince1970: timestamp)
                    dailyUsage[date] = value
                }
            }
        }
    }

    private func saveUsageData() {
        let encoded = dailyUsage.reduce(into: [String: Double]()) { result, pair in
            result[String(pair.key.timeIntervalSince1970)] = pair.value
        }

        if let data = try? JSONEncoder().encode(encoded) {
            UserDefaults.standard.set(data, forKey: usageKey)
        }
    }
}

struct EnergySaving: Identifiable {
    let id = UUID()
    let deviceID: String
    let suggestion: String
    let potentialSavings: Double
}

// MARK: - View

struct EnergyDashboardView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var energyManager = EnergyMonitoringManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text("Energy Dashboard")
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 80)
                    .padding(.top, 60)
                
                // Current Usage
                HStack(spacing: 30) {
                    EnergyStatCard(
                        title: "Current Usage",
                        value: String(format: "%.2f kW", energyManager.currentPowerUsage),
                        icon: "bolt.fill",
                        color: .yellow
                    )
                    
                    EnergyStatCard(
                        title: "Today's Cost",
                        value: String(format: "$%.2f", energyManager.getDailyCost()),
                        icon: "dollarsign.circle.fill",
                        color: .green
                    )
                    
                    EnergyStatCard(
                        title: "This Month",
                        value: String(format: "$%.2f", energyManager.getMonthlyCost()),
                        icon: "calendar",
                        color: .blue
                    )
                }
                .padding(.horizontal, 80)
                
                // Usage Chart
                VStack(alignment: .leading, spacing: 20) {
                    Text("Usage Trend (7 Days)")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    
                    // Chart placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 300)
                        .cornerRadius(15)
                        .overlay(
                            Text("Usage Chart")
                                .foregroundColor(.secondary)
                        )
                }
                .padding(.horizontal, 80)
                
                // Energy Savings Suggestions
                VStack(alignment: .leading, spacing: 20) {
                    Text("Savings Opportunities")
                        .font(.system(size: 18, weight: .bold))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    
                    ForEach(energyManager.energySavings) { saving in
                        EnergySavingCard(saving: saving)
                    }
                }
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 60)
        }
    }
}

struct EnergyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 35, weight: .bold))
            
            Text(title)
                .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(color.opacity(0.1))
        .cornerRadius(15)
    }
}

struct EnergySavingCard: View {
    let saving: EnergySaving
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 30))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(saving.suggestion)
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                
                Text("Potential savings: $\(String(format: "%.2f", saving.potentialSavings))/day")
                    .font(.system(size: 11))
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}