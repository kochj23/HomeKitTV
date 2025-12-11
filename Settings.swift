import Foundation
import HomeKit

/// Application settings and preferences manager
///
/// This class manages all user preferences and persistent storage using UserDefaults.
/// It provides a centralized location for app configuration including:
/// - Favorites management
/// - Activity history
/// - Display preferences
/// - Refresh rates
///
/// **Thread Safety**: All operations are performed on the main thread
/// **Persistence**: Uses UserDefaults with automatic synchronization
///
/// - Note: This is an ObservableObject to enable reactive UI updates
class Settings: ObservableObject {
    // MARK: - Singleton

    /// Shared settings instance
    static let shared = Settings()

    // MARK: - Published Properties

    /// Array of favorite accessory identifiers (UUIDs as strings)
    @Published var favoriteAccessoryIDs: Set<String> {
        didSet {
            saveFavorites()
        }
    }

    /// Array of favorite scene identifiers (UUIDs as strings)
    @Published var favoriteSceneIDs: Set<String> {
        didSet {
            saveFavorites()
        }
    }

    /// Activity history entries (limited to 50 most recent)
    ///
    /// **Memory Safety**: Automatically enforces 50-entry limit to prevent unbounded growth
    @Published var activityHistory: [ActivityEntry] = [] {
        didSet {
            // Enforce retention limit
            if activityHistory.count > 50 {
                activityHistory = Array(activityHistory.prefix(50))
            }
            saveHistory()
        }
    }

    /// Status message duration in seconds
    @Published var statusMessageDuration: Double {
        didSet {
            UserDefaults.standard.set(statusMessageDuration, forKey: Keys.statusMessageDuration)
        }
    }

    /// Auto-refresh interval in seconds (0 = disabled)
    @Published var autoRefreshInterval: Double {
        didSet {
            UserDefaults.standard.set(autoRefreshInterval, forKey: Keys.autoRefreshInterval)
        }
    }

    /// Show battery levels on accessory cards
    @Published var showBatteryLevels: Bool {
        didSet {
            UserDefaults.standard.set(showBatteryLevels, forKey: Keys.showBatteryLevels)
        }
    }

    /// Show reachability indicators
    @Published var showReachabilityIndicators: Bool {
        didSet {
            UserDefaults.standard.set(showReachabilityIndicators, forKey: Keys.showReachabilityIndicators)
        }
    }

    /// Font size multiplier (0.8 = Small, 1.0 = Medium, 1.2 = Large, 1.4 = Extra Large)
    @Published var fontSizeMultiplier: Double {
        didSet {
            UserDefaults.standard.set(fontSizeMultiplier, forKey: Keys.fontSizeMultiplier)
        }
    }

    /// Hide unreachable accessories from views
    @Published var hideUnreachableAccessories: Bool {
        didSet {
            UserDefaults.standard.set(hideUnreachableAccessories, forKey: Keys.hideUnreachableAccessories)
        }
    }

    /// Hide empty rooms (rooms with no accessories)
    @Published var hideEmptyRooms: Bool {
        didSet {
            UserDefaults.standard.set(hideEmptyRooms, forKey: Keys.hideEmptyRooms)
        }
    }

    /// Hide empty scenes (scenes with no actions)
    @Published var hideEmptyScenes: Bool {
        didSet {
            UserDefaults.standard.set(hideEmptyScenes, forKey: Keys.hideEmptyScenes)
        }
    }

    // MARK: - Private Properties

    /// UserDefaults keys
    private enum Keys {
        static let favoriteAccessoryIDs = "favoriteAccessoryIDs"
        static let favoriteSceneIDs = "favoriteSceneIDs"
        static let activityHistory = "activityHistory"
        static let statusMessageDuration = "statusMessageDuration"
        static let autoRefreshInterval = "autoRefreshInterval"
        static let showBatteryLevels = "showBatteryLevels"
        static let showReachabilityIndicators = "showReachabilityIndicators"
        static let fontSizeMultiplier = "fontSizeMultiplier"
        static let hideUnreachableAccessories = "hideUnreachableAccessories"
        static let hideEmptyRooms = "hideEmptyRooms"
        static let hideEmptyScenes = "hideEmptyScenes"
    }

    // MARK: - Initialization & Deinitialization

    private init() {
        // Load favorites
        if let favoriteAccessories = UserDefaults.standard.array(forKey: Keys.favoriteAccessoryIDs) as? [String] {
            self.favoriteAccessoryIDs = Set(favoriteAccessories)
        } else {
            self.favoriteAccessoryIDs = []
        }

        if let favoriteScenes = UserDefaults.standard.array(forKey: Keys.favoriteSceneIDs) as? [String] {
            self.favoriteSceneIDs = Set(favoriteScenes)
        } else {
            self.favoriteSceneIDs = []
        }

        // Load activity history
        if let historyData = UserDefaults.standard.data(forKey: Keys.activityHistory),
           let history = try? JSONDecoder().decode([ActivityEntry].self, from: historyData) {
            self.activityHistory = history
        } else {
            self.activityHistory = []
        }

        // Load preferences with defaults
        let loadedDuration = UserDefaults.standard.double(forKey: Keys.statusMessageDuration)
        self.statusMessageDuration = loadedDuration == 0 ? 3.0 : loadedDuration

        self.autoRefreshInterval = UserDefaults.standard.double(forKey: Keys.autoRefreshInterval)
        // Default 0 (disabled)

        let loadedBatteryPref = UserDefaults.standard.object(forKey: Keys.showBatteryLevels)
        self.showBatteryLevels = loadedBatteryPref == nil ? true : UserDefaults.standard.bool(forKey: Keys.showBatteryLevels)

        let loadedReachabilityPref = UserDefaults.standard.object(forKey: Keys.showReachabilityIndicators)
        self.showReachabilityIndicators = loadedReachabilityPref == nil ? true : UserDefaults.standard.bool(forKey: Keys.showReachabilityIndicators)

        // Load font size multiplier with default of 0.25 (Medium)
        let loadedFontSize = UserDefaults.standard.double(forKey: Keys.fontSizeMultiplier)
        self.fontSizeMultiplier = loadedFontSize == 0 ? 0.25 : loadedFontSize

        // Load filter preferences (default to false - show everything)
        self.hideUnreachableAccessories = UserDefaults.standard.bool(forKey: Keys.hideUnreachableAccessories)
        self.hideEmptyRooms = UserDefaults.standard.bool(forKey: Keys.hideEmptyRooms)
        self.hideEmptyScenes = UserDefaults.standard.bool(forKey: Keys.hideEmptyScenes)
    }

    /// Cleans up resources
    ///
    /// **Memory Safety**: Even though this is a singleton, proper cleanup is documented
    /// for testing and potential future refactoring
    deinit {
        // Note: Singleton typically lives for app lifetime
        // This deinit is here for completeness and future-proofing
        // If NotificationCenter observers are added in future, remove them here
    }

    // MARK: - Favorites Management

    /// Check if an accessory is favorited
    func isFavorite(_ accessory: HMAccessory) -> Bool {
        return favoriteAccessoryIDs.contains(accessory.uniqueIdentifier.uuidString)
    }

    /// Toggle favorite status for an accessory
    func toggleFavorite(_ accessory: HMAccessory) {
        let id = accessory.uniqueIdentifier.uuidString
        if favoriteAccessoryIDs.contains(id) {
            favoriteAccessoryIDs.remove(id)
        } else {
            favoriteAccessoryIDs.insert(id)
        }
    }

    /// Check if a scene is favorited
    func isFavorite(_ scene: HMActionSet) -> Bool {
        return favoriteSceneIDs.contains(scene.uniqueIdentifier.uuidString)
    }

    /// Toggle favorite status for a scene
    func toggleFavorite(_ scene: HMActionSet) {
        let id = scene.uniqueIdentifier.uuidString
        if favoriteSceneIDs.contains(id) {
            favoriteSceneIDs.remove(id)
        } else {
            favoriteSceneIDs.insert(id)
        }
    }

    /// Save favorites to persistent storage
    private func saveFavorites() {
        UserDefaults.standard.set(Array(favoriteAccessoryIDs), forKey: Keys.favoriteAccessoryIDs)
        UserDefaults.standard.set(Array(favoriteSceneIDs), forKey: Keys.favoriteSceneIDs)
    }

    // MARK: - Activity History

    /// Add an entry to activity history
    func addActivity(_ entry: ActivityEntry) {
        // Add to beginning
        activityHistory.insert(entry, at: 0)

        // Limit to 50 entries
        if activityHistory.count > 50 {
            activityHistory = Array(activityHistory.prefix(50))
        }
    }

    /// Clear all activity history
    func clearHistory() {
        activityHistory = []
    }

    /// Save history to persistent storage
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(activityHistory) {
            UserDefaults.standard.set(encoded, forKey: Keys.activityHistory)
        }
    }
}

// MARK: - Activity Entry Model

/// Represents a single activity history entry
struct ActivityEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let action: String
    let accessoryName: String
    let accessoryID: String
    let details: String?

    init(action: String, accessoryName: String, accessoryID: String, details: String? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.action = action
        self.accessoryName = accessoryName
        self.accessoryID = accessoryID
        self.details = details
    }

    /// Formatted timestamp string
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    /// Formatted relative time (e.g., "2 minutes ago")
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
