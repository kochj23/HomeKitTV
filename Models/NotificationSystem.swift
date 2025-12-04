import Foundation
import UserNotifications
import HomeKit

/// Notification type for HomeKit events
enum NotificationType: String, Codable {
    case accessoryOffline
    case lowBattery
    case motionDetected
    case doorOpened
    case temperatureAlert
    case leakDetected
    case smokeDetected
    case securityAlert
    case automationExecuted
    case sceneExecuted
    case custom
}

/// Notification priority level
enum NotificationPriority: String, Codable {
    case low
    case normal
    case high
    case critical
}

/// Home notification entry
///
/// Represents a notification event in the system.
struct HomeNotification: Identifiable, Codable {
    /// Unique identifier
    let id: UUID

    /// Type of notification
    let type: NotificationType

    /// Title of the notification
    var title: String

    /// Body message
    var body: String

    /// Priority level
    var priority: NotificationPriority

    /// Related accessory ID
    var accessoryID: UUID?

    /// Related accessory name
    var accessoryName: String?

    /// Timestamp
    let timestamp: Date

    /// Whether notification was read
    var isRead: Bool

    /// Whether notification was acted upon
    var isActioned: Bool

    /// Additional metadata
    var metadata: [String: String]

    /// Initialize a new notification
    init(type: NotificationType, title: String, body: String, priority: NotificationPriority = .normal, accessoryID: UUID? = nil, accessoryName: String? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.body = body
        self.priority = priority
        self.accessoryID = accessoryID
        self.accessoryName = accessoryName
        self.timestamp = Date()
        self.isRead = false
        self.isActioned = false
        self.metadata = metadata
    }
}

/// Notification rule for automatic alerts
///
/// Defines conditions under which notifications should be sent.
struct NotificationRule: Identifiable, Codable {
    /// Unique identifier
    let id: UUID

    /// Display name
    var name: String

    /// Type of notification to send
    var notificationType: NotificationType

    /// Accessory ID to monitor (nil = all accessories)
    var accessoryID: UUID?

    /// Condition (e.g., "battery < 20", "temperature > 80")
    var condition: String

    /// Whether rule is enabled
    var isEnabled: Bool

    /// Priority of notifications from this rule
    var priority: NotificationPriority

    /// Cooldown period in seconds (prevent spam)
    var cooldownSeconds: TimeInterval

    /// Last time this rule fired
    var lastFired: Date?

    /// Created date
    let createdAt: Date

    /// Initialize a new notification rule
    init(name: String, type: NotificationType, accessoryID: UUID? = nil, condition: String, priority: NotificationPriority = .normal, cooldownSeconds: TimeInterval = 300) {
        self.id = UUID()
        self.name = name
        self.notificationType = type
        self.accessoryID = accessoryID
        self.condition = condition
        self.isEnabled = true
        self.priority = priority
        self.cooldownSeconds = cooldownSeconds
        self.createdAt = Date()
    }
}

/// Notification manager
///
/// Handles creation, delivery, and management of notifications.
///
/// **Features**:
/// - Local notifications using UserNotifications framework
/// - In-app notification history
/// - Notification rules and automation
/// - Priority-based delivery
///
/// **Privacy**: Respects user notification settings
/// **Thread Safety**: All UI updates on main thread
class NotificationManager: NSObject, ObservableObject {
    /// Published array of all notifications
    @Published var notifications: [HomeNotification] = []

    /// Published array of notification rules
    @Published var rules: [NotificationRule] = []

    /// Whether notifications are authorized
    @Published var isAuthorized = false

    /// Unread notification count
    @Published var unreadCount: Int = 0

    /// UserDefaults keys
    private let notificationsKey = "com.homekittv.notifications"
    private let rulesKey = "com.homekittv.notificationRules"

    /// Notification center
    #if os(iOS) || os(watchOS)
    private let notificationCenter = UNUserNotificationCenter.current()
    #endif

    /// Singleton instance
    static let shared = NotificationManager()

    /// Private initializer
    private override init() {
        super.init()
        #if os(iOS) || os(watchOS)
        notificationCenter.delegate = self
        requestAuthorization()
        #endif
        loadData()
        updateUnreadCount()
    }

    // MARK: - Authorization

    /// Request notification permissions
    func requestAuthorization() {
        #if os(iOS) || os(watchOS)
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if let error = error {
                }
            }
        }
        #endif
    }

    // MARK: - Data Management

    /// Load notifications from storage
    private func loadData() {
        // Load notifications
        if let data = UserDefaults.standard.data(forKey: notificationsKey) {
            do {
                notifications = try JSONDecoder().decode([HomeNotification].self, from: data)
            } catch {
                notifications = []
            }
        }

        // Load rules
        if let data = UserDefaults.standard.data(forKey: rulesKey) {
            do {
                rules = try JSONDecoder().decode([NotificationRule].self, from: data)
            } catch {
                rules = createDefaultRules()
            }
        } else {
            rules = createDefaultRules()
        }

        updateUnreadCount()
    }

    /// Save data to storage
    private func saveData() {
        do {
            let notifData = try JSONEncoder().encode(notifications)
            UserDefaults.standard.set(notifData, forKey: notificationsKey)

            let rulesData = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(rulesData, forKey: rulesKey)
        } catch {
        }
    }

    /// Create default notification rules
    private func createDefaultRules() -> [NotificationRule] {
        return [
            NotificationRule(name: "Low Battery Alert", type: .lowBattery, condition: "battery < 20", priority: .high, cooldownSeconds: 3600),
            NotificationRule(name: "Motion Detected", type: .motionDetected, condition: "motion = true", priority: .normal, cooldownSeconds: 300),
            NotificationRule(name: "Door Opened", type: .doorOpened, condition: "contact = open", priority: .normal, cooldownSeconds: 60),
            NotificationRule(name: "Temperature Alert", type: .temperatureAlert, condition: "temperature > 80 OR temperature < 50", priority: .high, cooldownSeconds: 1800),
            NotificationRule(name: "Smoke Detected", type: .smokeDetected, condition: "smoke = detected", priority: .critical, cooldownSeconds: 0)
        ]
    }

    /// Update unread count
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }

    // MARK: - Notification Creation

    /// Send a notification
    ///
    /// Creates both a local system notification and an in-app notification entry.
    ///
    /// - Parameters:
    ///   - type: Type of notification
    ///   - title: Notification title
    ///   - body: Notification body
    ///   - priority: Priority level
    ///   - accessoryID: Related accessory UUID
    ///   - accessoryName: Related accessory name
    ///   - metadata: Additional data
    func sendNotification(type: NotificationType, title: String, body: String, priority: NotificationPriority = .normal, accessoryID: UUID? = nil, accessoryName: String? = nil, metadata: [String: String] = [:]) {
        guard isAuthorized else { return }

        // Create in-app notification
        let notification = HomeNotification(
            type: type,
            title: title,
            body: body,
            priority: priority,
            accessoryID: accessoryID,
            accessoryName: accessoryName,
            metadata: metadata
        )

        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.updateUnreadCount()
            self.saveData()
        }

        // Send system notification
        sendSystemNotification(notification)

        // Prune old notifications
        pruneOldNotifications()
    }

    /// Send system notification via UserNotifications
    private func sendSystemNotification(_ notification: HomeNotification) {
        #if os(iOS) || os(watchOS)
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = UNNotificationSound.default

        // Set category based on type
        content.categoryIdentifier = notification.type.rawValue

        // Set badge if critical
        if notification.priority == .critical {
            content.badge = NSNumber(value: unreadCount + 1)
        }

        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        notificationCenter.add(request) { error in
            if let error = error {
            }
        }
        #endif
    }

    // MARK: - Notification Management

    /// Mark notification as read
    func markAsRead(_ notification: HomeNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
            saveData()
        }
    }

    /// Mark all as read
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        saveData()
    }

    /// Delete notification
    func deleteNotification(_ notification: HomeNotification) {
        notifications.removeAll { $0.id == notification.id }
        updateUnreadCount()
        saveData()

        // Remove from notification center
        #if os(iOS) || os(watchOS)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [notification.id.uuidString])
        #endif
    }

    /// Clear all notifications
    func clearAll() {
        notifications.removeAll()
        updateUnreadCount()
        saveData()
        #if os(iOS) || os(watchOS)
        notificationCenter.removeAllDeliveredNotifications()
        #endif
    }

    /// Prune old notifications (keep last 100)
    private func pruneOldNotifications() {
        if notifications.count > 100 {
            notifications = Array(notifications.prefix(100))
            saveData()
        }
    }

    // MARK: - Rule Management

    /// Create a new notification rule
    func createRule(name: String, type: NotificationType, accessoryID: UUID?, condition: String, priority: NotificationPriority, cooldownSeconds: TimeInterval) {
        let rule = NotificationRule(
            name: name,
            type: type,
            accessoryID: accessoryID,
            condition: condition,
            priority: priority,
            cooldownSeconds: cooldownSeconds
        )
        rules.append(rule)
        saveData()
    }

    /// Update a rule
    func updateRule(_ rule: NotificationRule) {
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
            saveData()
        }
    }

    /// Delete a rule
    func deleteRule(_ rule: NotificationRule) {
        rules.removeAll { $0.id == rule.id }
        saveData()
    }

    /// Evaluate rules for an accessory state change
    ///
    /// Checks if any rules match the current state and sends notifications.
    ///
    /// - Parameters:
    ///   - accessory: The accessory that changed
    ///   - characteristic: The characteristic that changed
    func evaluateRules(for accessory: HMAccessory, characteristic: HMCharacteristic? = nil) {
        let now = Date()

        for rule in rules where rule.isEnabled {
            // Check cooldown
            if let lastFired = rule.lastFired,
               now.timeIntervalSince(lastFired) < rule.cooldownSeconds {
                continue
            }

            // Filter by accessory if specified
            if let ruleAccessoryID = rule.accessoryID,
               ruleAccessoryID != accessory.uniqueIdentifier {
                continue
            }

            // Evaluate condition (simplified - production would have proper parser)
            if evaluateCondition(rule.condition, for: accessory, characteristic: characteristic) {
                sendNotification(
                    type: rule.notificationType,
                    title: rule.name,
                    body: "Condition met: \(rule.condition)",
                    priority: rule.priority,
                    accessoryID: accessory.uniqueIdentifier,
                    accessoryName: accessory.name
                )

                // Update last fired
                if let index = rules.firstIndex(where: { $0.id == rule.id }) {
                    rules[index].lastFired = now
                    saveData()
                }
            }
        }
    }

    /// Evaluate a condition string
    ///
    /// Supports conditions like:
    /// - "battery < 20"
    /// - "temperature > 80"
    /// - "motion = true"
    /// - "contact = open"
    /// - "temperature > 80 OR temperature < 50"
    /// - "battery < 20 AND reachable = true"
    ///
    /// - Parameters:
    ///   - condition: The condition string to evaluate
    ///   - accessory: The accessory to check
    ///   - characteristic: Optional specific characteristic
    /// - Returns: True if condition is met
    private func evaluateCondition(_ condition: String, for accessory: HMAccessory, characteristic: HMCharacteristic?) -> Bool {
        let trimmed = condition.trimmingCharacters(in: .whitespaces)

        // Handle OR conditions
        if trimmed.contains(" OR ") {
            let parts = trimmed.components(separatedBy: " OR ")
            return parts.contains { evaluateCondition($0, for: accessory, characteristic: characteristic) }
        }

        // Handle AND conditions
        if trimmed.contains(" AND ") {
            let parts = trimmed.components(separatedBy: " AND ")
            return parts.allSatisfy { evaluateCondition($0, for: accessory, characteristic: characteristic) }
        }

        // Parse single condition: "property operator value"
        let operators = [">=", "<=", "!=", ">", "<", "="]
        var propertyName = ""
        var operatorString = ""
        var expectedValue = ""

        for op in operators {
            if let range = trimmed.range(of: op) {
                propertyName = String(trimmed[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
                operatorString = op
                expectedValue = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        guard !propertyName.isEmpty, !operatorString.isEmpty else {
            return false
        }

        // Get the actual value from the accessory
        let actualValue = getCharacteristicValue(for: propertyName, from: accessory, characteristic: characteristic)

        // Compare values based on operator
        return compareValues(actual: actualValue, expected: expectedValue, operator: operatorString)
    }

    /// Get characteristic value by property name
    private func getCharacteristicValue(for propertyName: String, from accessory: HMAccessory, characteristic: HMCharacteristic?) -> Any? {
        let property = propertyName.lowercased()

        // Special case: reachability
        if property == "reachable" || property == "reachability" {
            return accessory.isReachable
        }

        // Search through all services for the characteristic
        for service in accessory.services {
            for char in service.characteristics {
                let charType = char.characteristicType

                // Match characteristic by property name
                if property == "battery" && charType == HMCharacteristicTypeBatteryLevel {
                    return char.value as? Int
                }
                else if property == "temperature" && charType == HMCharacteristicTypeCurrentTemperature {
                    return char.value as? Double
                }
                else if property == "humidity" && charType == HMCharacteristicTypeCurrentRelativeHumidity {
                    return char.value as? Double
                }
                else if property == "motion" && charType == HMCharacteristicTypeMotionDetected {
                    return char.value as? Bool
                }
                else if property == "contact" && charType == "0000006A-0000-1000-8000-0026BB765291" { // Contact Sensor State
                    return char.value as? Int
                }
                else if property == "smoke" && charType == HMCharacteristicTypeSmokeDetected {
                    return char.value as? Int
                }
                else if property == "leak" && charType == HMCharacteristicTypeLeakDetected {
                    return char.value as? Int
                }
                else if property == "co" && charType == HMCharacteristicTypeCarbonMonoxideDetected {
                    return char.value as? Int
                }
                else if property == "co2" && charType == HMCharacteristicTypeCarbonDioxideLevel {
                    return char.value as? Double
                }
                else if property == "airquality" && charType == HMCharacteristicTypeAirQuality {
                    return char.value as? Int
                }
                else if property == "brightness" && charType == HMCharacteristicTypeBrightness {
                    return char.value as? Int
                }
                else if property == "powersupply" || property == "power" {
                    if charType == HMCharacteristicTypePowerState {
                        return char.value as? Bool
                    }
                }
            }
        }

        // Check if the specific characteristic was provided
        if let char = characteristic {
            return char.value
        }

        return nil
    }

    /// Compare two values using the specified operator
    private func compareValues(actual: Any?, expected: String, operator op: String) -> Bool {
        guard let actual = actual else { return false }

        // Handle boolean comparisons
        if let boolValue = actual as? Bool {
            let expectedBool = expected.lowercased() == "true" || expected == "1" || expected.lowercased() == "yes"
            switch op {
            case "=": return boolValue == expectedBool
            case "!=": return boolValue != expectedBool
            default: return false
            }
        }

        // Handle string comparisons (e.g., contact = open)
        if let stringValue = actual as? String {
            switch op {
            case "=": return stringValue.lowercased() == expected.lowercased()
            case "!=": return stringValue.lowercased() != expected.lowercased()
            default: return false
            }
        }

        // Handle integer comparisons
        if let intValue = actual as? Int {
            // Special cases for contact sensor (0 = detected/open, 1 = not detected/closed)
            if expected.lowercased() == "open" || expected.lowercased() == "detected" {
                return op == "=" ? intValue == 0 : intValue != 0
            } else if expected.lowercased() == "closed" || expected.lowercased() == "clear" {
                return op == "=" ? intValue == 1 : intValue != 1
            }

            guard let expectedInt = Int(expected) else { return false }
            switch op {
            case "=": return intValue == expectedInt
            case "!=": return intValue != expectedInt
            case "<": return intValue < expectedInt
            case ">": return intValue > expectedInt
            case "<=": return intValue <= expectedInt
            case ">=": return intValue >= expectedInt
            default: return false
            }
        }

        // Handle double comparisons
        if let doubleValue = actual as? Double {
            guard let expectedDouble = Double(expected) else { return false }
            switch op {
            case "=": return abs(doubleValue - expectedDouble) < 0.01
            case "!=": return abs(doubleValue - expectedDouble) >= 0.01
            case "<": return doubleValue < expectedDouble
            case ">": return doubleValue > expectedDouble
            case "<=": return doubleValue <= expectedDouble
            case ">=": return doubleValue >= expectedDouble
            default: return false
            }
        }

        // Handle float comparisons
        if let floatValue = actual as? Float {
            guard let expectedFloat = Float(expected) else { return false }
            switch op {
            case "=": return abs(floatValue - expectedFloat) < 0.01
            case "!=": return abs(floatValue - expectedFloat) >= 0.01
            case "<": return floatValue < expectedFloat
            case ">": return floatValue > expectedFloat
            case "<=": return floatValue <= expectedFloat
            case ">=": return floatValue >= expectedFloat
            default: return false
            }
        }

        return false
    }

    /// Clean up notification center delegate to prevent memory leaks
    deinit {
        #if os(iOS) || os(watchOS)
        notificationCenter.delegate = nil
        #endif
    }

}

// MARK: - UNUserNotificationCenterDelegate

#if os(iOS) || os(watchOS)
extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier

        if let notification = notifications.first(where: { $0.id.uuidString == identifier }) {
            markAsRead(notification)
        }

        completionHandler()
    }
}
#endif
