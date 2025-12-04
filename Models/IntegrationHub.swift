import Foundation
import HomeKit
import CoreLocation

/// Integration hub for external services
///
/// Provides integration with:
/// - Weather services
/// - Calendar events
/// - IFTTT-style webhooks
/// - REST API for external control
class IntegrationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = IntegrationManager()

    @Published var weather: WeatherData?
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var webhooks: [Webhook] = []
    @Published var isLoadingWeather = false

    private let locationManager = CLLocationManager()
    private let webhooksKey = "com.homekittv.webhooks"

    private override init() {
        super.init()
        locationManager.delegate = self
        loadWebhooks()
    }

    // MARK: - Weather Integration

    /// Fetch weather data for current location
    func fetchWeather() {
        isLoadingWeather = true

        // Request location authorization
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    /// Location manager delegate - got location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.first != nil else { return }

        // Fetch weather using Apple Weather (WeatherKit would require additional setup)
        // For now, create mock data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.weather = WeatherData(
                temperature: 72,
                condition: "Partly Cloudy",
                humidity: 65,
                windSpeed: 8,
                highTemp: 78,
                lowTemp: 62,
                sunrise: Date(),
                sunset: Date().addingTimeInterval(43200),
                location: "Current Location"
            )
            self.isLoadingWeather = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoadingWeather = false
    }

    // MARK: - Calendar Integration

    /// Load calendar events for today
    func loadCalendarEvents() {
        // Note: Would require EventKit framework for real implementation
        // Creating sample events for demonstration
        let calendar = Calendar.current
        let today = Date()

        calendarEvents = [
            CalendarEvent(
                title: "Morning Routine",
                startTime: calendar.date(bySettingHour: 7, minute: 0, second: 0, of: today) ?? today,
                endTime: calendar.date(bySettingHour: 7, minute: 30, second: 0, of: today) ?? today,
                suggestedScene: "Good Morning"
            ),
            CalendarEvent(
                title: "Work Time",
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: today) ?? today,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: today) ?? today,
                suggestedScene: "Focus Mode"
            )
        ]
    }

    /// Get upcoming calendar events (next 24 hours)
    func upcomingEvents() -> [CalendarEvent] {
        let now = Date()
        let tomorrow = now.addingTimeInterval(86400)
        return calendarEvents.filter { $0.startTime > now && $0.startTime < tomorrow }
    }

    // MARK: - Webhook Management

    /// Create a webhook
    func createWebhook(name: String, url: String, trigger: WebhookTrigger, method: String = "POST") {
        let webhook = Webhook(name: name, url: url, trigger: trigger, method: method)
        webhooks.append(webhook)
        saveWebhooks()
    }

    /// Trigger a webhook with comprehensive security validation
    ///
    /// **Security Measures**:
    /// - Validates URL format and scheme (HTTPS only)
    /// - Prevents SSRF attacks by blocking private IP ranges
    /// - Validates HTTP method
    /// - Timeout protection (10 seconds)
    ///
    /// - Parameters:
    ///   - webhook: The webhook configuration to trigger
    ///   - data: Optional JSON data to send with the request
    func triggerWebhook(_ webhook: Webhook, data: [String: Any]? = nil) {
        // Validate URL format
        guard let url = URL(string: webhook.url) else { return }

        // Security: Only allow HTTPS to prevent man-in-the-middle attacks
        guard url.scheme == "https" else { return }

        // Security: Validate URL to prevent SSRF attacks
        guard isValidWebhookURL(url) else { return }

        // Security: Validate HTTP method (allow only safe methods)
        let allowedMethods = ["GET", "POST", "PUT", "PATCH", "DELETE"]
        guard allowedMethods.contains(webhook.method.uppercased()) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = webhook.method
        request.timeoutInterval = 10.0 // Security: Timeout protection

        if let data = data {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: data)
        }

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Error occurred (silently ignore)
                } else {
                    // Success (silently ignore)
                }
            }
        }.resume()
    }

    /// Validate webhook URL to prevent SSRF attacks
    ///
    /// **Security**: Blocks requests to private IP ranges and localhost
    ///
    /// - Parameter url: The URL to validate
    /// - Returns: `true` if URL is safe, `false` otherwise
    private func isValidWebhookURL(_ url: URL) -> Bool {
        guard let host = url.host else { return false }

        // Block localhost
        if host == "localhost" || host == "127.0.0.1" || host == "::1" {
            return false
        }

        // Block private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16)
        let blockedPatterns = [
            "^10\\.",
            "^172\\.(1[6-9]|2[0-9]|3[01])\\.",
            "^192\\.168\\.",
            "^169\\.254\\.", // Link-local
            "^0\\.", // Current network
            "^127\\." // Loopback
        ]

        for pattern in blockedPatterns {
            if host.range(of: pattern, options: .regularExpression) != nil {
                return false
            }
        }

        return true
    }

    /// Delete webhook
    func deleteWebhook(_ webhook: Webhook) {
        webhooks.removeAll { $0.id == webhook.id }
        saveWebhooks()
    }

    // MARK: - Automation Triggers

    /// Check if weather matches condition for automation
    func checkWeatherCondition(_ condition: WeatherCondition) -> Bool {
        guard let weather = weather else { return false }

        switch condition {
        case .temperatureAbove(let temp):
            return weather.temperature > temp
        case .temperatureBelow(let temp):
            return weather.temperature < temp
        case .humidityAbove(let humidity):
            return weather.humidity > humidity
        case .condition(let conditionName):
            return weather.condition.localizedCaseInsensitiveContains(conditionName)
        }
    }

    // MARK: - Persistence

    /// Load webhooks securely from Keychain
    ///
    /// **Security**: Webhooks contain sensitive URLs and are encrypted in Keychain
    private func loadWebhooks() {
        do {
            guard let data = try SecureStorage.shared.retrieveData(key: webhooksKey) else {
                // Try migrating from old UserDefaults storage
                migrateWebhooksFromUserDefaults()
                return
            }
            let webhooks = try JSONDecoder().decode([Webhook].self, from: data)
            self.webhooks = webhooks
        } catch {
            // Failed to load webhooks - start with empty array
            self.webhooks = []
        }
    }

    /// Save webhooks securely to Keychain
    ///
    /// **Security**: Webhooks contain sensitive URLs and are encrypted in Keychain
    private func saveWebhooks() {
        do {
            let data = try JSONEncoder().encode(webhooks)
            try SecureStorage.shared.save(key: webhooksKey, data: data)
        } catch {
            // Failed to save webhooks
        }
    }

    /// Migrate webhooks from insecure UserDefaults to secure Keychain
    ///
    /// This is a one-time migration for existing users.
    private func migrateWebhooksFromUserDefaults() {
        if let data = UserDefaults.standard.data(forKey: webhooksKey),
           let webhooks = try? JSONDecoder().decode([Webhook].self, from: data) {
            // Save to secure storage
            self.webhooks = webhooks
            saveWebhooks()

            // Delete from UserDefaults
            UserDefaults.standard.removeObject(forKey: webhooksKey)
        }
    }

    /// Clean up location manager delegate to prevent memory leaks
    deinit {
        locationManager.delegate = nil
    }
}

// MARK: - Models

/// Weather data model
struct WeatherData: Codable {
    let temperature: Int
    let condition: String
    let humidity: Int
    let windSpeed: Int
    let highTemp: Int
    let lowTemp: Int
    let sunrise: Date
    let sunset: Date
    let location: String

    var icon: String {
        switch condition.lowercased() {
        case let c where c.contains("clear"): return "sun.max.fill"
        case let c where c.contains("cloud"): return "cloud.fill"
        case let c where c.contains("rain"): return "cloud.rain.fill"
        case let c where c.contains("snow"): return "cloud.snow.fill"
        case let c where c.contains("storm"): return "cloud.bolt.fill"
        default: return "cloud.sun.fill"
        }
    }
}

/// Calendar event model
struct CalendarEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let startTime: Date
    let endTime: Date
    let suggestedScene: String?

    init(title: String, startTime: Date, endTime: Date, suggestedScene: String? = nil) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.suggestedScene = suggestedScene
    }

    var isNow: Bool {
        let now = Date()
        return startTime <= now && endTime >= now
    }

    var isUpcoming: Bool {
        startTime > Date()
    }
}

/// Webhook model
struct Webhook: Identifiable, Codable {
    let id: UUID
    var name: String
    var url: String
    var trigger: WebhookTrigger
    var method: String
    var enabled: Bool

    init(name: String, url: String, trigger: WebhookTrigger, method: String, enabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.url = url
        self.trigger = trigger
        self.method = method
        self.enabled = enabled
    }
}

/// Webhook trigger types
enum WebhookTrigger: String, Codable, CaseIterable {
    case sceneExecuted = "Scene Executed"
    case accessoryTurnedOn = "Accessory Turned On"
    case accessoryTurnedOff = "Accessory Turned Off"
    case temperatureChange = "Temperature Change"
    case motionDetected = "Motion Detected"
    case doorOpened = "Door Opened"
    case custom = "Custom"
}

/// Weather condition for automation
enum WeatherCondition {
    case temperatureAbove(Int)
    case temperatureBelow(Int)
    case humidityAbove(Int)
    case condition(String)
}

/// Vacation mode settings
struct VacationMode: Codable {
    var isEnabled: Bool
    var startDate: Date
    var endDate: Date
    var randomizeLights: Bool
    var notifyOnMotion: Bool
    var lockAllDoors: Bool
    var adjustThermostat: Bool
    var targetTemperature: Int
}
