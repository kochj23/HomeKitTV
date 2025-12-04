import Foundation
import HomeKit

/// Predictive intelligence engine for smart suggestions
///
/// Analyzes usage patterns and provides:
/// - Smart scene suggestions
/// - Automation recommendations
/// - Anomaly detection
/// - Behavior pattern recognition
class PredictiveEngine: ObservableObject {
    static let shared = PredictiveEngine()

    @Published var suggestions: [SmartSuggestion] = []
    @Published var usagePatterns: [UsagePattern] = []
    @Published var anomalies: [Anomaly] = []

    private let patternsKey = "com.homekittv.usagePatterns"
    private let settings = Settings.shared

    private init() {
        loadPatterns()
    }

    // MARK: - Pattern Analysis

    /// Analyze activity history to detect patterns
    func analyzePatterns() {
        let history = settings.activityHistory

        // Group activities by hour
        var hourlyActivity: [Int: Int] = [:]
        var deviceFrequency: [String: Int] = [:]
        var sceneFrequency: [String: Int] = [:]

        for entry in history {
            let hour = Calendar.current.component(.hour, from: entry.timestamp)
            hourlyActivity[hour, default: 0] += 1
            deviceFrequency[entry.accessoryName, default: 0] += 1

            if entry.action.contains("Scene") {
                sceneFrequency[entry.accessoryName, default: 0] += 1
            }
        }

        // Find most active hours
        let activeHours = hourlyActivity.sorted { $0.value > $1.value }.prefix(3)

        // Find most used devices
        let frequentDevices = deviceFrequency.sorted { $0.value > $1.value }.prefix(5)

        // Create patterns
        usagePatterns = activeHours.map { hour, count in
            UsagePattern(
                type: .timeBasedActivity,
                description: "Peak activity at \(hour):00 (\(count) actions)",
                confidence: Double(count) / Double(history.count),
                metadata: ["hour": "\(hour)", "count": "\(count)"]
            )
        } + frequentDevices.map { device, count in
            UsagePattern(
                type: .frequentDevice,
                description: "Frequently control: \(device) (\(count) times)",
                confidence: Double(count) / Double(history.count),
                metadata: ["device": device, "count": "\(count)"]
            )
        }

        savePatterns()
    }

    // MARK: - Smart Suggestions

    /// Generate smart suggestions based on patterns
    func generateSuggestions(homeManager: HomeKitManager) {
        suggestions.removeAll()

        // Analyze activity history
        let history = settings.activityHistory
        guard !history.isEmpty else { return }

        // Suggestion 1: Create automation for repeated actions
        let hourlyActions = Dictionary(grouping: history) { entry in
            Calendar.current.component(.hour, from: entry.timestamp)
        }

        for (hour, actions) in hourlyActions where actions.count >= 3 {
            // Find most common action at this hour
            let actionCounts = Dictionary(grouping: actions) { $0.action }
            if let mostCommon = actionCounts.max(by: { $0.value.count < $1.value.count }) {
                suggestions.append(SmartSuggestion(
                    type: .createAutomation,
                    title: "Create Automation",
                    description: "You often \(mostCommon.key.lowercased()) around \(hour):00. Create an automation?",
                    priority: .high,
                    metadata: ["hour": "\(hour)", "action": mostCommon.key]
                ))
            }
        }

        // Suggestion 2: Create scene from current states
        let onAccessories = homeManager.accessories.filter { homeManager.getPowerState($0) }
        if onAccessories.count >= 3 {
            suggestions.append(SmartSuggestion(
                type: .createScene,
                title: "Save Current State",
                description: "Create a scene from current device states (\(onAccessories.count) devices on)",
                priority: .medium,
                metadata: ["accessory_count": "\(onAccessories.count)"]
            ))
        }

        // Suggestion 3: Add to favorites
        let deviceUsage = Dictionary(grouping: history) { $0.accessoryID }
        let frequentDevices = deviceUsage.filter { $0.value.count >= 5 }

        for (deviceID, _) in frequentDevices {
            if let accessory = homeManager.accessories.first(where: { $0.uniqueIdentifier.uuidString == deviceID }),
               !settings.isFavorite(accessory) {
                suggestions.append(SmartSuggestion(
                    type: .addToFavorites,
                    title: "Add to Favorites",
                    description: "You frequently control \(accessory.name). Add to favorites?",
                    priority: .low,
                    metadata: ["accessory_id": deviceID]
                ))
            }
        }

        // Suggestion 4: Energy saving
        let alwaysOnDevices = homeManager.accessories.filter { accessory in
            let recentActions = history.filter { $0.accessoryID == accessory.uniqueIdentifier.uuidString }
            let onlyOnActions = recentActions.allSatisfy { $0.action.contains("on") }
            return recentActions.count > 5 && onlyOnActions
        }

        if !alwaysOnDevices.isEmpty {
            suggestions.append(SmartSuggestion(
                type: .energySaving,
                title: "Energy Saving Opportunity",
                description: "\(alwaysOnDevices.count) devices are always on. Create a 'Good Night' scene to turn them off?",
                priority: .medium,
                metadata: ["device_count": "\(alwaysOnDevices.count)"]
            ))
        }

        // Suggestion 5: Service groups
        let lights = homeManager.accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLightbulb } }
        if lights.count >= 5 && ServiceGroupManager.shared.serviceGroups.isEmpty {
            suggestions.append(SmartSuggestion(
                type: .createServiceGroup,
                title: "Create Service Group",
                description: "You have \(lights.count) lights. Group them for easier control?",
                priority: .medium,
                metadata: ["light_count": "\(lights.count)"]
            ))
        }

        // Sort by priority
        suggestions.sort { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Anomaly Detection

    /// Detect unusual activity or device behavior
    func detectAnomalies(homeManager: HomeKitManager) {
        anomalies.removeAll()

        // Anomaly 1: Unreachable devices
        let unreachable = homeManager.accessories.filter { !$0.isReachable }
        if !unreachable.isEmpty {
            anomalies.append(Anomaly(
                type: .deviceUnreachable,
                severity: .warning,
                description: "\(unreachable.count) \(unreachable.count == 1 ? "device is" : "devices are") unreachable",
                affectedDevices: unreachable.map { $0.name }
            ))
        }

        // Anomaly 2: Low battery devices
        let lowBattery = homeManager.accessories.filter { homeManager.isLowBattery($0) }
        if !lowBattery.isEmpty {
            anomalies.append(Anomaly(
                type: .lowBattery,
                severity: .warning,
                description: "\(lowBattery.count) \(lowBattery.count == 1 ? "device has" : "devices have") low battery",
                affectedDevices: lowBattery.map { $0.name }
            ))
        }

        // Anomaly 3: Unusual activity time
        let history = settings.activityHistory
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let recentActions = history.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: now) }

        if hour >= 2 && hour <= 5 && recentActions.count > 10 {
            anomalies.append(Anomaly(
                type: .unusualActivity,
                severity: .high,
                description: "Unusual activity detected at \(hour):00 (\(recentActions.count) actions)",
                affectedDevices: []
            ))
        }

        // Anomaly 4: Energy spike
        // This would require energy monitoring to be more sophisticated
    }

    /// Dismiss a suggestion
    func dismissSuggestion(_ suggestion: SmartSuggestion) {
        suggestions.removeAll { $0.id == suggestion.id }
    }

    // MARK: - Persistence

    private func loadPatterns() {
        if let data = UserDefaults.standard.data(forKey: patternsKey),
           let patterns = try? JSONDecoder().decode([UsagePattern].self, from: data) {
            usagePatterns = patterns
        }
    }

    private func savePatterns() {
        if let data = try? JSONEncoder().encode(usagePatterns) {
            UserDefaults.standard.set(data, forKey: patternsKey)
        }
    }
}

// MARK: - Models

/// Smart suggestion model
struct SmartSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let title: String
    let description: String
    let priority: Priority
    let metadata: [String: String]

    enum SuggestionType {
        case createAutomation
        case createScene
        case addToFavorites
        case energySaving
        case createServiceGroup
        case optimizeSchedule
    }

    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
}

/// Usage pattern model
struct UsagePattern: Identifiable, Codable {
    let id: UUID
    let type: PatternType
    let description: String
    let confidence: Double
    let detectedAt: Date
    let metadata: [String: String]

    init(type: PatternType, description: String, confidence: Double, metadata: [String: String]) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.confidence = confidence
        self.detectedAt = Date()
        self.metadata = metadata
    }

    enum PatternType: String, Codable {
        case timeBasedActivity = "Time-Based Activity"
        case frequentDevice = "Frequent Device"
        case sceneUsage = "Scene Usage"
        case roomActivity = "Room Activity"
    }
}

/// Anomaly detection model
struct Anomaly: Identifiable {
    let id: UUID
    let type: AnomalyType
    let severity: Severity
    let description: String
    let affectedDevices: [String]
    let detectedAt: Date

    init(type: AnomalyType, severity: Severity, description: String, affectedDevices: [String]) {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.description = description
        self.affectedDevices = affectedDevices
        self.detectedAt = Date()
    }

    enum AnomalyType {
        case deviceUnreachable
        case lowBattery
        case unusualActivity
        case energySpike
        case securityBreach
    }

    enum Severity: Int {
        case info = 1
        case warning = 2
        case high = 3
        case critical = 4
    }
}
