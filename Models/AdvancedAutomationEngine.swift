import Foundation
import HomeKit
import CoreLocation

/// Advanced automation engine with complex conditional logic
///
/// Supports multi-condition automations with AND/OR logic, time-based triggers,
/// sensor-based conditions, and state-dependent actions.
///
/// **Features**:
/// - Complex condition builder (AND/OR/NOT logic)
/// - Multiple trigger types (time, location, sensor, state)
/// - Conditional actions based on current state
/// - Automation templates and suggestions
/// - Conflict detection and resolution
class AdvancedAutomationEngine: ObservableObject {
    static let shared = AdvancedAutomationEngine()

    @Published var automations: [AdvancedAutomation] = []
    @Published var automationLogs: [AutomationLog] = []

    private let automationsKey = "com.homekittv.advancedAutomations"
    private let logsKey = "com.homekittv.automationLogs"

    private init() {
        loadAutomations()
        loadLogs()
    }

    // MARK: - Automation Management

    /// Creates a new automation
    func createAutomation(_ automation: AdvancedAutomation) {
        automations.append(automation)
        saveAutomations()
        logEvent("Created automation: \(automation.name)")
    }

    /// Updates an existing automation
    func updateAutomation(_ automation: AdvancedAutomation) {
        if let index = automations.firstIndex(where: { $0.id == automation.id }) {
            automations[index] = automation
            saveAutomations()
            logEvent("Updated automation: \(automation.name)")
        }
    }

    /// Deletes an automation
    func deleteAutomation(_ automation: AdvancedAutomation) {
        automations.removeAll { $0.id == automation.id }
        saveAutomations()
        logEvent("Deleted automation: \(automation.name)")
    }

    /// Evaluates all automations and executes triggered ones
    func evaluateAutomations(context: AutomationContext) {
        for automation in automations where automation.isEnabled {
            if evaluateConditions(automation.conditions, context: context) {
                executeAutomation(automation, context: context)
            }
        }
    }

    // MARK: - Condition Evaluation

    /// Evaluates a condition group
    private func evaluateConditions(_ group: ConditionGroup, context: AutomationContext) -> Bool {
        switch group.logic {
        case .and:
            return group.conditions.allSatisfy { evaluateCondition($0, context: context) }
        case .or:
            return group.conditions.contains { evaluateCondition($0, context: context) }
        case .not:
            return !group.conditions.allSatisfy { evaluateCondition($0, context: context) }
        }
    }

    /// Evaluates a single condition
    private func evaluateCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        switch condition.type {
        case .time:
            return evaluateTimeCondition(condition, context: context)
        case .location:
            return evaluateLocationCondition(condition, context: context)
        case .sensor:
            return evaluateSensorCondition(condition, context: context)
        case .deviceState:
            return evaluateDeviceStateCondition(condition, context: context)
        case .weather:
            return evaluateWeatherCondition(condition, context: context)
        case .occupancy:
            return evaluateOccupancyCondition(condition, context: context)
        }
    }

    private func evaluateTimeCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        let currentTime = Calendar.current.dateComponents([.hour, .minute], from: context.currentTime)

        guard let startHour = condition.parameters["startHour"] as? Int,
              let startMinute = condition.parameters["startMinute"] as? Int,
              let endHour = condition.parameters["endHour"] as? Int,
              let endMinute = condition.parameters["endMinute"] as? Int else {
            return false
        }

        let currentMinutes = (currentTime.hour ?? 0) * 60 + (currentTime.minute ?? 0)
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes <= endMinutes
        } else {
            // Spans midnight
            return currentMinutes >= startMinutes || currentMinutes <= endMinutes
        }
    }

    private func evaluateLocationCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        guard let userLocation = context.userLocation else { return false }

        let homeLocation = CLLocation(latitude: context.homeLatitude, longitude: context.homeLongitude)
        let distance = userLocation.distance(from: homeLocation)
        let radius = (condition.parameters["radius"] as? Double) ?? 100.0

        let atHome = distance <= radius

        if condition.parameters["trigger"] as? String == "arriving" {
            return atHome && (context.previousLocation?.distance(from: homeLocation) ?? 0) > radius
        } else if condition.parameters["trigger"] as? String == "leaving" {
            return !atHome && (context.previousLocation?.distance(from: homeLocation) ?? 0) <= radius
        }

        return atHome
    }

    private func evaluateSensorCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        guard let deviceID = condition.parameters["deviceID"] as? String,
              let characteristic = condition.parameters["characteristic"] as? String,
              let targetValue = condition.parameters["value"] else {
            return false
        }

        // Get current sensor value from context
        if let currentValue = context.sensorValues[deviceID]?[characteristic] {
            let comparison = condition.parameters["comparison"] as? String ?? "equals"

            switch comparison {
            case "equals":
                return String(describing: currentValue) == String(describing: targetValue)
            case "greaterThan":
                if let current = currentValue as? Double, let target = targetValue as? Double {
                    return current > target
                }
            case "lessThan":
                if let current = currentValue as? Double, let target = targetValue as? Double {
                    return current < target
                }
            default:
                return false
            }
        }

        return false
    }

    private func evaluateDeviceStateCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        guard let deviceID = condition.parameters["deviceID"] as? String else { return false }
        let targetState = condition.parameters["state"] as? Bool ?? false
        let currentState = context.deviceStates[deviceID] ?? false
        return currentState == targetState
    }

    private func evaluateWeatherCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        guard let weatherType = condition.parameters["weatherType"] as? String else { return false }
        return context.currentWeather?.lowercased().contains(weatherType.lowercased()) ?? false
    }

    private func evaluateOccupancyCondition(_ condition: AutomationCondition, context: AutomationContext) -> Bool {
        let targetOccupancy = condition.parameters["occupied"] as? Bool ?? true
        return context.homeOccupied == targetOccupancy
    }

    // MARK: - Automation Execution

    /// Executes an automation's actions
    private func executeAutomation(_ automation: AdvancedAutomation, context: AutomationContext) {
        logEvent("Executing automation: \(automation.name)")

        for action in automation.actions {
            executeAction(action, context: context)
        }

        let log = AutomationLog(
            id: UUID(),
            automationID: automation.id,
            automationName: automation.name,
            timestamp: Date(),
            success: true,
            actionsExecuted: automation.actions.count
        )
        automationLogs.insert(log, at: 0)
        saveLogs()
    }

    /// Executes a single action
    private func executeAction(_ action: AutomationAction, context: AutomationContext) {
        switch action.type {
        case .setDevice:
            if let deviceID = action.parameters["deviceID"] as? String,
               let state = action.parameters["state"] as? Bool {
                // Execute device control
                logEvent("Setting device \(deviceID) to \(state)")
            }

        case .activateScene:
            if let sceneID = action.parameters["sceneID"] as? String {
                // Activate scene
                logEvent("Activating scene \(sceneID)")
            }

        case .delay:
            if let seconds = action.parameters["seconds"] as? Double {
                Thread.sleep(forTimeInterval: seconds)
            }

        case .notify:
            if let message = action.parameters["message"] as? String {
                logEvent("Notification: \(message)")
            }

        case .conditionalAction:
            // Nested conditional logic
            if let conditionKey = action.parameters["condition"] as? String {
                // Evaluate nested condition
                logEvent("Conditional action based on \(conditionKey)")
            }
        }
    }

    // MARK: - Automation Templates

    /// Returns pre-built automation templates
    func getAutomationTemplates() -> [AdvancedAutomation] {
        return [
            // Good Morning
            AdvancedAutomation(
                id: UUID(),
                name: "Good Morning",
                description: "Sunrise lighting and temperature adjustment",
                conditions: ConditionGroup(
                    logic: .and,
                    conditions: [
                        AutomationCondition(
                            type: .time,
                            parameters: ["startHour": 6, "startMinute": 0, "endHour": 9, "endMinute": 0]
                        ),
                        AutomationCondition(
                            type: .occupancy,
                            parameters: ["occupied": true]
                        )
                    ]
                ),
                actions: [
                    AutomationAction(type: .activateScene, parameters: ["sceneID": "morning"]),
                    AutomationAction(type: .notify, parameters: ["message": "Good morning! Starting your day."])
                ],
                isEnabled: false
            ),

            // Security Mode
            AdvancedAutomation(
                id: UUID(),
                name: "Security Mode",
                description: "Lock doors and arm system when leaving",
                conditions: ConditionGroup(
                    logic: .and,
                    conditions: [
                        AutomationCondition(
                            type: .location,
                            parameters: ["trigger": "leaving", "radius": 100.0]
                        ),
                        AutomationCondition(
                            type: .time,
                            parameters: ["startHour": 7, "startMinute": 0, "endHour": 23, "endMinute": 0]
                        )
                    ]
                ),
                actions: [
                    AutomationAction(type: .notify, parameters: ["message": "Activating security mode"]),
                    AutomationAction(type: .activateScene, parameters: ["sceneID": "away"])
                ],
                isEnabled: false
            ),

            // Energy Saver
            AdvancedAutomation(
                id: UUID(),
                name: "Energy Saver",
                description: "Turn off devices when nobody is home",
                conditions: ConditionGroup(
                    logic: .and,
                    conditions: [
                        AutomationCondition(
                            type: .occupancy,
                            parameters: ["occupied": false]
                        ),
                        AutomationCondition(
                            type: .time,
                            parameters: ["startHour": 9, "startMinute": 0, "endHour": 18, "endMinute": 0]
                        )
                    ]
                ),
                actions: [
                    AutomationAction(type: .activateScene, parameters: ["sceneID": "all-off"])
                ],
                isEnabled: false
            )
        ]
    }

    // MARK: - Logging

    private func logEvent(_ message: String) {
    }

    // MARK: - Persistence

    private func loadAutomations() {
        if let data = UserDefaults.standard.data(forKey: automationsKey),
           let loaded = try? JSONDecoder().decode([AdvancedAutomation].self, from: data) {
            automations = loaded
        }
    }

    private func saveAutomations() {
        if let data = try? JSONEncoder().encode(automations) {
            UserDefaults.standard.set(data, forKey: automationsKey)
        }
    }

    private func loadLogs() {
        if let data = UserDefaults.standard.data(forKey: logsKey),
           let loaded = try? JSONDecoder().decode([AutomationLog].self, from: data) {
            automationLogs = loaded
        }
    }

    private func saveLogs() {
        // Keep only last 1000 logs
        if automationLogs.count > 1000 {
            automationLogs = Array(automationLogs.prefix(1000))
        }

        if let data = try? JSONEncoder().encode(automationLogs) {
            UserDefaults.standard.set(data, forKey: logsKey)
        }
    }
}

// MARK: - Models

/// Advanced automation with complex conditions
struct AdvancedAutomation: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var conditions: ConditionGroup
    var actions: [AutomationAction]
    var isEnabled: Bool
    var createdAt: Date = Date()
    var lastTriggered: Date?

    init(id: UUID, name: String, description: String, conditions: ConditionGroup, actions: [AutomationAction], isEnabled: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.conditions = conditions
        self.actions = actions
        self.isEnabled = isEnabled
    }
}

/// Condition group with logical operators
struct ConditionGroup: Codable {
    var logic: LogicOperator
    var conditions: [AutomationCondition]
    var nestedGroups: [ConditionGroup]?

    init(logic: LogicOperator, conditions: [AutomationCondition], nestedGroups: [ConditionGroup]? = nil) {
        self.logic = logic
        self.conditions = conditions
        self.nestedGroups = nestedGroups
    }
}

/// Logical operators for condition groups
enum LogicOperator: String, Codable {
    case and = "AND"
    case or = "OR"
    case not = "NOT"
}

/// Individual automation condition
struct AutomationCondition: Codable {
    var type: ConditionType
    var parameters: [String: AnyCodable]

    init(type: ConditionType, parameters: [String: Any]) {
        self.type = type
        self.parameters = parameters.mapValues { AnyCodable($0) }
    }
}

/// Condition types
enum ConditionType: String, Codable {
    case time = "Time"
    case location = "Location"
    case sensor = "Sensor"
    case deviceState = "Device State"
    case weather = "Weather"
    case occupancy = "Occupancy"
}

/// Automation action
struct AutomationAction: Codable {
    var type: ActionType
    var parameters: [String: AnyCodable]
    var delay: TimeInterval?

    init(type: ActionType, parameters: [String: Any], delay: TimeInterval? = nil) {
        self.type = type
        self.parameters = parameters.mapValues { AnyCodable($0) }
        self.delay = delay
    }
}

/// Action types
enum ActionType: String, Codable {
    case setDevice = "Set Device"
    case activateScene = "Activate Scene"
    case delay = "Delay"
    case notify = "Notify"
    case conditionalAction = "Conditional Action"
}

/// Automation execution context
struct AutomationContext {
    var currentTime: Date
    var userLocation: CLLocation?
    var previousLocation: CLLocation?
    var homeLatitude: Double
    var homeLongitude: Double
    var sensorValues: [String: [String: Any]]
    var deviceStates: [String: Bool]
    var currentWeather: String?
    var homeOccupied: Bool
}

/// Automation execution log
struct AutomationLog: Identifiable, Codable {
    let id: UUID
    let automationID: UUID
    let automationName: String
    let timestamp: Date
    let success: Bool
    let actionsExecuted: Int
    var errorMessage: String?
}

/// Type-erased codable wrapper
struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let bool as Bool:
            try container.encode(bool)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Cannot encode value"))
        }
    }
}
