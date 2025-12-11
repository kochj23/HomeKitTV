import Foundation
import HomeKit

/// HomeKitManager is the central controller for all HomeKit operations in the application.
///
/// This class manages the HomeKit framework integration, providing a reactive interface
/// through Combine's ObservableObject protocol. It handles:
/// - Home discovery and management
/// - Accessory control (lights, outlets, switches, thermostats, fans)
/// - Room organization
/// - Scene execution
/// - Real-time state updates via HomeKit delegates
///
/// **Thread Safety**: All HomeKit delegate callbacks are dispatched to the main thread
/// to ensure safe property updates and UI synchronization.
///
/// **Memory Management**: The deinit method properly cleans up delegates to prevent
/// retain cycles and memory leaks.
///
/// - Note: Requires HomeKit entitlements and proper Info.plist configuration
/// - Warning: HomeKit operations may fail if user hasn't granted authorization
class HomeKitManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    /// Array of all homes available to the user
    @Published var homes: [HMHome] = []

    /// The user's primary home (main residence)
    @Published var primaryHome: HMHome?

    /// All rooms in the primary home, sorted alphabetically
    @Published var rooms: [HMRoom] = []

    /// All accessories in the primary home, sorted alphabetically
    @Published var accessories: [HMAccessory] = []

    /// All scenes (action sets) in the primary home, sorted alphabetically
    @Published var scenes: [HMActionSet] = []

    /// Whether HomeKit authorization has been granted
    @Published var isAuthorized = false

    /// User-facing status message for operations (auto-clears after timeout)
    @Published var statusMessage = ""

    /// Loading state for initial data fetch
    @Published var isLoading = true

    /// List of accessories that failed during the last scene execution
    @Published var failedAccessories: [HMAccessory] = []

    /// All HomeKit triggers/automations in the primary home
    @Published var triggers: [HMTrigger] = []

    /// Current selected home (defaults to primary)
    @Published var currentHome: HMHome?

    /// Search query for filtering accessories/rooms/scenes
    @Published var searchQuery = "" {
        didSet {
            scheduleSearch()
        }
    }

    /// Debounced search results
    @Published private(set) var searchResults: SearchResults = SearchResults()

    /// Retry count for failed operations
    @Published var retryCount = 0

    // MARK: - Search Management

    /// Search debounce task
    private var searchTask: Task<Void, Never>?

    /// Search results cache
    private var searchCache: [String: SearchResults] = [:]

    /// Search results structure
    struct SearchResults {
        var accessories: [HMAccessory] = []
        var rooms: [HMRoom] = []
        var scenes: [HMActionSet] = []
    }

    /// Schedules a debounced search
    ///
    /// **Performance**: 300ms debounce prevents excessive filtering on every keystroke
    private func scheduleSearch() {
        // Cancel previous search task
        searchTask?.cancel()

        // Schedule new search after debounce delay
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms debounce

            guard let self = self, !Task.isCancelled else { return }

            await self.performSearch()
        }
    }

    /// Performs the actual search operation
    ///
    /// **Performance**: Uses caching to avoid redundant filtering
    @MainActor
    private func performSearch() async {
        let query = searchQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Return empty results for empty query
        guard !query.isEmpty else {
            searchResults = SearchResults()
            return
        }

        // Check cache first
        if let cached = searchCache[query] {
            searchResults = cached
            return
        }

        // Perform search
        let results = SearchResults(
            accessories: accessories.filter { $0.name.localizedCaseInsensitiveContains(query) },
            rooms: rooms.filter { $0.name.localizedCaseInsensitiveContains(query) },
            scenes: scenes.filter { $0.name.localizedCaseInsensitiveContains(query) }
        )

        // Cache results
        searchCache[query] = results

        // Limit cache size
        if searchCache.count > 20 {
            searchCache.removeAll()
        }

        searchResults = results
    }

    // MARK: - Computed Properties (Filtered)

    /// Filtered accessories based on settings and search query
    var filteredAccessories: [HMAccessory] {
        var filtered = accessories

        // Apply reachability filter
        if settings.hideUnreachableAccessories {
            filtered = filtered.filter { $0.isReachable }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return filtered
    }

    /// Filtered rooms based on settings and search query
    var filteredRooms: [HMRoom] {
        var filtered = rooms

        // Apply empty rooms filter
        if settings.hideEmptyRooms {
            filtered = filtered.filter { room in
                !accessories(for: room).isEmpty
            }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return filtered
    }

    /// Filtered scenes based on settings and search query
    var filteredScenes: [HMActionSet] {
        var filtered = scenes

        // Apply empty scenes filter
        if settings.hideEmptyScenes {
            filtered = filtered.filter { !$0.actions.isEmpty }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }
        }

        return filtered
    }

    // MARK: - Private Properties

    /// The HomeKit home manager instance (handles home discovery and updates)
    private var homeManager: HMHomeManager?

    /// Settings instance for preferences and favorites
    private let settings = Settings.shared

    /// Auto-refresh timer
    private var refreshTimer: Timer?

    /// Maximum retry attempts for failed operations
    private let maxRetryAttempts = 3

    // MARK: - Initialization & Deinitialization

    /// Initializes the HomeKitManager and sets up the home manager delegate
    ///
    /// This method creates the HMHomeManager instance which will automatically
    /// discover homes and trigger delegate callbacks when ready.
    override init() {
        super.init()
        homeManager = HMHomeManager()
        homeManager?.delegate = self
    }

    /// Cleans up delegates to prevent memory leaks
    ///
    /// **Memory Safety**: This is critical for preventing retain cycles between
    /// the manager, home manager, and home delegates.
    deinit {
        refreshTimer?.invalidate()
        searchTask?.cancel()
        homeManager?.delegate = nil
        primaryHome?.delegate = nil
        currentHome?.delegate = nil
    }

    // MARK: - Data Loading

    /// Loads all HomeKit data from the primary home
    ///
    /// This method fetches and sorts all rooms, accessories, and scenes from
    /// the user's primary home asynchronously for better performance.
    ///
    /// **Performance**: Uses async/await to prevent blocking the main thread
    /// **Side Effects**:
    /// - Updates `primaryHome`, `rooms`, `accessories`, `scenes`
    /// - Sets `statusMessage` with success/error info
    /// - Sets `isLoading` to false
    /// - Auto-clears status message after 3 seconds
    ///
    /// - Warning: If no primary home is configured, sets an error message
    func loadData() {
        Task {
            await loadDataAsync()
        }
    }

    /// Async implementation of loadData for better performance
    ///
    /// **Performance**: Processes large homes without blocking UI
    @MainActor
    private func loadDataAsync() async {
        guard let home = homeManager?.primaryHome else {
            statusMessage = "No primary home configured"
            isLoading = false
            return
        }

        primaryHome = home
        currentHome = home
        home.delegate = self

        // Load data in parallel using async let
        async let sortedRooms = Task {
            home.rooms.sorted { $0.name < $1.name }
        }.value

        async let sortedAccessories = Task {
            home.accessories.sorted { $0.name < $1.name }
        }.value

        async let sortedScenes = Task {
            home.actionSets.sorted { $0.name < $1.name }
        }.value

        async let sortedTriggers = Task {
            home.triggers.sorted { $0.name < $1.name }
        }.value

        // Await all results
        rooms = await sortedRooms
        accessories = await sortedAccessories
        scenes = await sortedScenes
        triggers = await sortedTriggers

        statusMessage = "Loaded \(accessories.count) accessories in \(rooms.count) rooms"
        isLoading = false

        // Setup auto-refresh if enabled
        setupAutoRefresh()

        // Clear status message after configured duration
        let duration = settings.statusMessageDuration
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                if self.statusMessage.hasPrefix("Loaded") {
                    self.statusMessage = ""
                }
            }
        }
    }

    /// Incrementally updates a single accessory without full reload
    ///
    /// **Performance**: Updates only changed accessory, avoiding expensive full sort
    @MainActor
    func updateAccessory(_ accessory: HMAccessory) {
        if let index = accessories.firstIndex(where: { $0.uniqueIdentifier == accessory.uniqueIdentifier }) {
            accessories[index] = accessory
        }
    }

    /// Incrementally updates a single room without full reload
    ///
    /// **Performance**: Updates only changed room, avoiding expensive full sort
    @MainActor
    func updateRoom(_ room: HMRoom) {
        if let index = rooms.firstIndex(where: { $0.uniqueIdentifier == room.uniqueIdentifier }) {
            rooms[index] = room
        }
    }

    /// Incrementally updates a single scene without full reload
    ///
    /// **Performance**: Updates only changed scene, avoiding expensive full sort
    @MainActor
    func updateScene(_ scene: HMActionSet) {
        if let index = scenes.firstIndex(where: { $0.uniqueIdentifier == scene.uniqueIdentifier }) {
            scenes[index] = scene
        }
    }

    // MARK: - Accessory Management

    /// Returns all accessories in a specific room, sorted alphabetically
    ///
    /// - Parameter room: The room to get accessories from
    /// - Returns: Array of accessories sorted by name
    func accessories(for room: HMRoom) -> [HMAccessory] {
        return room.accessories.sorted { $0.name < $1.name }
    }

    // MARK: - Scene Execution

    /// Executes a HomeKit scene (action set)
    ///
    /// This method triggers all actions defined in the scene asynchronously.
    /// The status message is automatically cleared after 3 seconds.
    ///
    /// - Parameter scene: The action set to execute
    ///
    /// **Side Effects**:
    /// - Updates `statusMessage` with success/error info
    /// - Executes all actions in the scene
    ///
    /// **Thread Safety**: Callback is dispatched to main thread
    ///
    /// - Warning: Requires primary home to be available
    /// Executes a scene and tracks which accessories failed
    ///
    /// This method attempts to execute all actions in a scene and then verifies
    /// which accessories actually responded. Failed accessories are tracked in
    /// the `failedAccessories` property.
    ///
    /// **Memory Safety**: Uses [weak self] to prevent retain cycles in callbacks
    ///
    /// - Parameter scene: The action set (scene) to execute
    func executeScene(_ scene: HMActionSet) {
        guard let home = primaryHome else {
            statusMessage = "No home available"
            failedAccessories = []
            return
        }

        // Clear previous failures
        failedAccessories = []

        // Get all accessories involved in this scene
        var sceneAccessories: [HMAccessory] = []
        for action in scene.actions {
            if let charAction = action as? HMCharacteristicWriteAction<NSCopying>,
               let accessory = charAction.characteristic.service?.accessory {
                if !sceneAccessories.contains(where: { $0.uniqueIdentifier == accessory.uniqueIdentifier }) {
                    sceneAccessories.append(accessory)
                }
            }
        }

        home.executeActionSet(scene) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                if let error = error {
                    self.statusMessage = "Scene execution failed: \(error.localizedDescription)"
                    self.failedAccessories = sceneAccessories
                } else {
                    // Wait a moment for accessories to respond, then check their status
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        guard let self = self else { return }

                        // Check which accessories are not responding
                        var failedList: [HMAccessory] = []
                        for accessory in sceneAccessories {
                            if !accessory.isReachable {
                                failedList.append(accessory)
                            }
                        }

                        self.failedAccessories = failedList

                        if failedList.isEmpty {
                            self.statusMessage = "✓ Scene '\(scene.name)' executed: All \(sceneAccessories.count) devices responded"
                        } else {
                            let successCount = sceneAccessories.count - failedList.count
                            self.statusMessage = "⚠️ Scene '\(scene.name)': \(successCount) succeeded, \(failedList.count) failed"
                        }

                        // Clear status message after 5 seconds (longer to read failure details)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                            self?.statusMessage = ""
                            self?.failedAccessories = []
                        }
                    }
                }
            }
        }
    }

    // MARK: - Accessory Control

    /// Toggles an accessory's power state (on/off)
    ///
    /// Finds the first service with a power state characteristic and toggles it.
    /// This is a convenience method for quickly controlling accessories.
    ///
    /// - Parameter accessory: The accessory to toggle
    ///
    /// **Side Effects**:
    /// - Updates `statusMessage` if no controllable service found
    /// - Delegates to `toggleService(_:)` for actual control
    ///
    /// - Warning: Shows error if accessory has no power state characteristic
    func toggleAccessory(_ accessory: HMAccessory) {
        guard let service = accessory.services.first(where: {
            $0.characteristics.contains(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        }) else {
            statusMessage = "No controllable service found"
            return
        }

        toggleService(service)
    }

    /// Toggles a specific service's power state
    ///
    /// Reads the current power state, inverts it, and writes the new value.
    /// This is a two-step process: read current value, then write inverted value.
    ///
    /// - Parameter service: The service to toggle
    ///
    /// **Side Effects**:
    /// - Updates `statusMessage` with operation result
    /// - Auto-clears status message after 2 seconds
    /// - Triggers HomeKit delegate callbacks on state change
    ///
    /// **Thread Safety**: All callbacks are dispatched to main thread
    ///
    /// - Warning: Shows error if service has no power state characteristic
    /// - Note: Uses nested callbacks: read then write
    func toggleService(_ service: HMService) {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypePowerState
        }) else {
            statusMessage = "No power state characteristic"
            return
        }

        characteristic.readValue { error in
            if let error = error {
                DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                    self.statusMessage = "Read error: \(error.localizedDescription)"
                }
                return
            }

            let currentValue = characteristic.value as? Bool ?? false
            let newValue = !currentValue

            characteristic.writeValue(newValue) { error in
                DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                    if let error = error {
                        self.statusMessage = "Write error: \(error.localizedDescription)"
                    } else {
                        self.statusMessage = "\(service.accessory?.name ?? "Device") turned \(newValue ? "on" : "off")"
                    }

                    // Clear status message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        guard let self = self else { return }
                        self.statusMessage = ""
                    }
                }
            }
        }
    }

    /// Sets the brightness level for a dimmable light
    ///
    /// Writes a brightness value (0-100) to the specified characteristic.
    /// The status message is automatically cleared after 2 seconds.
    ///
    /// - Parameters:
    ///   - characteristic: The brightness characteristic to modify
    ///   - value: The brightness level (0-100)
    ///
    /// **Side Effects**:
    /// - Updates `statusMessage` with operation result
    /// - Auto-clears status message after 2 seconds
    ///
    /// **Thread Safety**: Callback is dispatched to main thread
    ///
    /// - Warning: Value should be in range 0-100
    func setBrightness(_ characteristic: HMCharacteristic, value: Int) {
        characteristic.writeValue(value) { error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Brightness error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Brightness set to \(value)%"
                }

                // Clear status message after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self = self else { return }
                    self.statusMessage = ""
                }
            }
        }
    }

    // MARK: - State Queries

    /// Gets the current power state of an accessory
    ///
    /// Searches for the first service with a power state characteristic
    /// and returns its current value.
    ///
    /// - Parameter accessory: The accessory to query
    /// - Returns: `true` if accessory is on, `false` if off or no power state found
    ///
    /// - Note: This is a synchronous read of cached characteristic value
    /// - Warning: Returns `false` if accessory has no power state characteristic
    func getPowerState(_ accessory: HMAccessory) -> Bool {
        guard let service = accessory.services.first(where: {
            $0.characteristics.contains(where: { $0.characteristicType == HMCharacteristicTypePowerState })
        }),
        let characteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypePowerState
        }) else {
            return false
        }

        return characteristic.value as? Bool ?? false
    }

    // MARK: - Auto-Refresh

    /// Sets up auto-refresh timer based on settings
    private func setupAutoRefresh() {
        refreshTimer?.invalidate()

        let interval = settings.autoRefreshInterval
        guard interval > 0 else { return }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.loadData()
        }
    }

    // MARK: - Home Management

    /// Switch to a different home
    func switchHome(_ home: HMHome) {
        currentHome = home
        primaryHome = home
        loadData()
        logActivity(action: "Switched Home", accessoryName: home.name, accessoryID: home.uniqueIdentifier.uuidString, details: nil)
    }

    // MARK: - Favorites

    /// Get favorite accessories
    func favoriteAccessories() -> [HMAccessory] {
        accessories.filter { settings.isFavorite($0) }
    }

    /// Get favorite scenes
    func favoriteScenes() -> [HMActionSet] {
        scenes.filter { settings.isFavorite($0) }
    }

    // MARK: - Thermostat Controls

    /// Set target temperature for a thermostat
    func setTargetTemperature(_ service: HMService, temperature: Double, completion: @escaping (Error?) -> Void) {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeTargetTemperature
        }) else {
            completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "No target temperature characteristic"]))
            return
        }

        characteristic.writeValue(temperature) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Temperature error: \(error.localizedDescription)"
                    self.handleError(error, retryAction: { [weak self] in
                        guard let self = self else { return }
                        self.setTargetTemperature(service, temperature: temperature, completion: completion)
                    })
                } else {
                    self.statusMessage = "Temperature set to \(Int(temperature))°"
                    self.logActivity(action: "Set Temperature", accessoryName: service.accessory?.name ?? "Thermostat", accessoryID: service.accessory?.uniqueIdentifier.uuidString ?? "", details: "\(Int(temperature))°")
                }
                completion(error)
            }
        }
    }

    /// Set thermostat mode (heat, cool, auto, off)
    func setThermostatMode(_ service: HMService, mode: Int, completion: @escaping (Error?) -> Void) {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == "00000033-0000-1000-8000-0026BB765291" // Target Heating Cooling State
        }) else {
            completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "No heating/cooling mode characteristic"]))
            return
        }

        characteristic.writeValue(mode) { [weak self] (error: Error?) in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Mode error: \(error.localizedDescription)"
                } else {
                    let modeName = ["Off", "Heat", "Cool", "Auto"][mode]
                    self.statusMessage = "Mode set to \(modeName)"
                    self.logActivity(action: "Set Thermostat Mode", accessoryName: service.accessory?.name ?? "Thermostat", accessoryID: service.accessory?.uniqueIdentifier.uuidString ?? "", details: modeName)
                }
                completion(error)
            }
        }
    }

    /// Get current temperature from thermostat
    func getCurrentTemperature(_ service: HMService) -> Double? {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeCurrentTemperature
        }) else {
            return nil
        }
        return characteristic.value as? Double
    }

    /// Get target temperature from thermostat
    func getTargetTemperature(_ service: HMService) -> Double? {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeTargetTemperature
        }) else {
            return nil
        }
        return characteristic.value as? Double
    }

    // MARK: - Color Controls

    /// Set hue for a color-capable light (0-360 degrees)
    func setHue(_ characteristic: HMCharacteristic, value: Double, completion: @escaping (Error?) -> Void) {
        characteristic.writeValue(value) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Hue error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Hue set to \(Int(value))°"
                    self.logActivity(action: "Set Hue", accessoryName: characteristic.service?.accessory?.name ?? "Light", accessoryID: characteristic.service?.accessory?.uniqueIdentifier.uuidString ?? "", details: "\(Int(value))°")
                }
                completion(error)
            }
        }
    }

    /// Set saturation for a color-capable light (0-100%)
    func setSaturation(_ characteristic: HMCharacteristic, value: Double, completion: @escaping (Error?) -> Void) {
        characteristic.writeValue(value) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Saturation error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Saturation set to \(Int(value))%"
                    self.logActivity(action: "Set Saturation", accessoryName: characteristic.service?.accessory?.name ?? "Light", accessoryID: characteristic.service?.accessory?.uniqueIdentifier.uuidString ?? "", details: "\(Int(value))%")
                }
                completion(error)
            }
        }
    }

    /// Set color temperature for a tunable white light (140-500 mireds)
    func setColorTemperature(_ characteristic: HMCharacteristic, value: Int, completion: @escaping (Error?) -> Void) {
        characteristic.writeValue(value) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Color temperature error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Color temperature set"
                    self.logActivity(action: "Set Color Temperature", accessoryName: characteristic.service?.accessory?.name ?? "Light", accessoryID: characteristic.service?.accessory?.uniqueIdentifier.uuidString ?? "", details: "\(value) mireds")
                }
                completion(error)
            }
        }
    }

    // MARK: - Fan Controls

    /// Set fan rotation speed (0-100%)
    func setFanSpeed(_ characteristic: HMCharacteristic, speed: Double, completion: @escaping (Error?) -> Void) {
        characteristic.writeValue(speed) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Fan speed error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Fan speed set to \(Int(speed))%"
                    self.logActivity(action: "Set Fan Speed", accessoryName: characteristic.service?.accessory?.name ?? "Fan", accessoryID: characteristic.service?.accessory?.uniqueIdentifier.uuidString ?? "", details: "\(Int(speed))%")
                }
                completion(error)
            }
        }
    }

    /// Set fan rotation direction
    func setFanRotationDirection(_ characteristic: HMCharacteristic, clockwise: Bool, completion: @escaping (Error?) -> Void) {
        let value = clockwise ? 0 : 1
        characteristic.writeValue(value) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Rotation error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Rotation set to \(clockwise ? "clockwise" : "counter-clockwise")"
                    self.logActivity(action: "Set Fan Direction", accessoryName: characteristic.service?.accessory?.name ?? "Fan", accessoryID: characteristic.service?.accessory?.uniqueIdentifier.uuidString ?? "", details: clockwise ? "Clockwise" : "Counter-clockwise")
                }
                completion(error)
            }
        }
    }

    // MARK: - Lock Controls

    /// Lock or unlock a door lock
    func setLockState(_ service: HMService, locked: Bool, completion: @escaping (Error?) -> Void) {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == "0000001E-0000-1000-8000-0026BB765291" // Lock Target State
        }) else {
            completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "No lock state characteristic"]))
            return
        }

        let value = locked ? 1 : 0
        characteristic.writeValue(value) { [weak self] (error: Error?) in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Lock error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "\(locked ? "Locked" : "Unlocked") \(service.accessory?.name ?? "Lock")"
                    self.logActivity(action: locked ? "Locked" : "Unlocked", accessoryName: service.accessory?.name ?? "Lock", accessoryID: service.accessory?.uniqueIdentifier.uuidString ?? "", details: nil)
                }
                completion(error)
            }
        }
    }

    /// Get current lock state
    func getLockState(_ service: HMService) -> Bool? {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == "0000001D-0000-1000-8000-0026BB765291" // Current Lock State
        }) else {
            return nil
        }
        // 0 = unsecured, 1 = secured
        return (characteristic.value as? Int) == 1
    }

    // MARK: - Window Covering Controls

    /// Set window covering position (0-100%, 0 = fully closed, 100 = fully open)
    func setWindowCoveringPosition(_ characteristic: HMCharacteristic, position: Int, completion: @escaping (Error?) -> Void) {
        characteristic.writeValue(position) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Position error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Position set to \(position)%"
                    self.logActivity(action: "Set Window Position", accessoryName: characteristic.service?.accessory?.name ?? "Window Covering", accessoryID: characteristic.service?.accessory?.uniqueIdentifier.uuidString ?? "", details: "\(position)%")
                }
                completion(error)
            }
        }
    }

    /// Get current window covering position
    func getWindowCoveringPosition(_ service: HMService) -> Int? {
        guard let characteristic = service.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypeTargetPosition
        }) else {
            return nil
        }
        return characteristic.value as? Int
    }

    // MARK: - Sensor Reading

    /// Get battery level for an accessory (0-100%)
    func getBatteryLevel(_ accessory: HMAccessory) -> Int? {
        for service in accessory.services {
            if let characteristic = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeBatteryLevel
            }) {
                return characteristic.value as? Int
            }
        }
        return nil
    }

    /// Get low battery status
    func isLowBattery(_ accessory: HMAccessory) -> Bool {
        for service in accessory.services {
            if let characteristic = service.characteristics.first(where: {
                $0.characteristicType == HMCharacteristicTypeStatusLowBattery
            }) {
                return (characteristic.value as? Int) == 1
            }
        }
        return false
    }

    /// Get all sensor readings for an accessory
    func getSensorReadings(_ accessory: HMAccessory) -> [String: Any] {
        var readings: [String: Any] = [:]

        for service in accessory.services {
            for characteristic in service.characteristics {
                guard let value = characteristic.value else { continue }

                switch characteristic.characteristicType {
                case HMCharacteristicTypeCurrentTemperature:
                    readings["Temperature"] = "\(String(format: "%.1f", value as? Double ?? 0))°"
                case HMCharacteristicTypeCurrentRelativeHumidity:
                    readings["Humidity"] = "\(Int(value as? Double ?? 0))%"
                case HMCharacteristicTypeAirQuality:
                    let qualityNames = ["Unknown", "Excellent", "Good", "Fair", "Inferior", "Poor"]
                    let quality = value as? Int ?? 0
                    readings["Air Quality"] = qualityNames[min(quality, 5)]
                case HMCharacteristicTypeMotionDetected:
                    readings["Motion"] = (value as? Bool ?? false) ? "Detected" : "Clear"
                case HMCharacteristicTypeContactState:
                    readings["Contact"] = (value as? Int ?? 0) == 1 ? "Open" : "Closed"
                case HMCharacteristicTypeCarbonDioxideLevel:
                    readings["CO2"] = "\(Int(value as? Double ?? 0)) ppm"
                case HMCharacteristicTypeCarbonMonoxideLevel:
                    readings["CO"] = "\(Int(value as? Double ?? 0)) ppm"
                case "0000006B-0000-1000-8000-0026BB765291": // Light Level
                    readings["Light Level"] = "\(String(format: "%.1f", value as? Double ?? 0)) lux"
                default:
                    break
                }
            }
        }

        return readings
    }

    // MARK: - Automation Management

    /// Get all automations (triggers)
    func getAutomations() -> [HMTrigger] {
        return triggers
    }

    /// Enable or disable an automation
    func setAutomationEnabled(_ trigger: HMTrigger, enabled: Bool, completion: @escaping (Error?) -> Void) {
        #if os(tvOS)
        // Trigger enable/disable is not available on tvOS
        completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature not available on tvOS"]))
        #else
        trigger.enable(enabled) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Automation error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Automation \(enabled ? "enabled" : "disabled")"
                    self.logActivity(action: enabled ? "Enabled Automation" : "Disabled Automation", accessoryName: trigger.name, accessoryID: trigger.uniqueIdentifier.uuidString, details: nil)
                }
                completion(error)
            }
        }
        #endif
    }

    // MARK: - Scene Management

    /// Create a new scene
    func createScene(name: String, completion: @escaping (HMActionSet?, Error?) -> Void) {
        #if os(tvOS)
        // Scene creation is not available on tvOS
        completion(nil, NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature not available on tvOS"]))
        #else
        guard let home = currentHome else {
            completion(nil, NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "No home available"]))
            return
        }

        home.addActionSet(withName: name) { [weak self] actionSet, error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Scene creation error: \(error.localizedDescription)"
                } else if let actionSet = actionSet {
                    self.statusMessage = "Created scene: \(name)"
                    self?.scenes = home.actionSets.sorted { $0.name < $1.name }
                    self.logActivity(action: "Created Scene", accessoryName: name, accessoryID: actionSet.uniqueIdentifier.uuidString, details: nil)
                }
                completion(actionSet, error)
            }
        }
        #endif
    }

    /// Delete a scene
    func deleteScene(_ scene: HMActionSet, completion: @escaping (Error?) -> Void) {
        #if os(tvOS)
        // Scene deletion is not available on tvOS
        completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature not available on tvOS"]))
        #else
        guard let home = currentHome else {
            completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "No home available"]))
            return
        }

        home.removeActionSet(scene) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Scene deletion error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Deleted scene: \(scene.name)"
                    self?.scenes = home.actionSets.sorted { $0.name < $1.name }
                    self.logActivity(action: "Deleted Scene", accessoryName: scene.name, accessoryID: scene.uniqueIdentifier.uuidString, details: nil)
                }
                completion(error)
            }
        }
        #endif
    }

    /// Add action to scene (e.g., turn on a light, set brightness)
    func addActionToScene(_ scene: HMActionSet, characteristic: HMCharacteristic, value: Any, completion: @escaping (Error?) -> Void) {
        #if os(tvOS)
        // Action set modification is not available on tvOS
        completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature not available on tvOS"]))
        #else
        guard let copyableValue = value as? NSCopying else {
            completion(NSError(domain: "HomeKitTV", code: -1, userInfo: [NSLocalizedDescriptionKey: "Value must be NSCopying"]))
            return
        }

        let action = HMCharacteristicWriteAction(characteristic: characteristic, targetValue: copyableValue)

        scene.addAction(action) { [weak self] error in
            DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
                if let error = error {
                    self.statusMessage = "Add action error: \(error.localizedDescription)"
                } else {
                    self.statusMessage = "Action added to scene"
                    self.logActivity(action: "Added Action to Scene", accessoryName: scene.name, accessoryID: scene.uniqueIdentifier.uuidString, details: characteristic.service?.accessory?.name)
                }
                completion(error)
            }
        }
        #endif
    }

    // MARK: - Activity Logging

    /// Log an activity to history
    private func logActivity(action: String, accessoryName: String, accessoryID: String, details: String?) {
        let entry = ActivityEntry(action: action, accessoryName: accessoryName, accessoryID: accessoryID, details: details)
        settings.addActivity(entry)
    }

    /// Get activity history
    func getActivityHistory() -> [ActivityEntry] {
        return settings.activityHistory
    }

    /// Clear activity history
    func clearActivityHistory() {
        settings.clearHistory()
        statusMessage = "Activity history cleared"
    }

    // MARK: - Error Handling

    /// Handle error with retry mechanism
    ///
    /// **Memory Safety**: Uses [weak self] to prevent retain cycles during async retry
    private func handleError(_ error: Error, retryAction: @escaping () -> Void) {
        guard retryCount < maxRetryAttempts else {
            statusMessage = "Failed after \(maxRetryAttempts) attempts"
            retryCount = 0
            return
        }

        retryCount += 1
        statusMessage = "Retrying... (Attempt \(retryCount)/\(maxRetryAttempts))"

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            retryAction()
        }
    }
}

// MARK: - HMHomeManagerDelegate

/// HomeKit Home Manager delegate implementation
///
/// These methods handle system-level HomeKit events such as home discovery,
/// primary home changes, and home additions.
///
/// **Thread Safety**: All methods dispatch to main thread for UI updates
extension HomeKitManager: HMHomeManagerDelegate {
    /// Called when the list of homes is updated
    ///
    /// This is the initial callback after HomeKit authorization is granted.
    ///
    /// - Parameter manager: The home manager that updated
    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.homes = manager.homes
            self.isAuthorized = true
            self.loadData()
        }
    }

    /// Called when the primary home changes
    ///
    /// This happens when the user changes their primary home in the Home app.
    ///
    /// - Parameter manager: The home manager that updated
    func homeManagerDidUpdatePrimaryHome(_ manager: HMHomeManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.loadData()
        }
    }

    /// Called when a new home is added
    ///
    /// - Parameters:
    ///   - manager: The home manager
    ///   - home: The home that was added
    func homeManager(_ manager: HMHomeManager, didAdd home: HMHome) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.homes = manager.homes
            self.loadData()
        }
    }
}

// MARK: - HMHomeDelegate

/// HomeKit Home delegate implementation
///
/// These methods handle home-level events such as accessory and room changes.
/// Now uses incremental updates instead of full reloads for better performance.
///
/// **Performance**: Incremental updates avoid expensive full sorting operations
/// **Thread Safety**: All methods dispatch to main thread for UI updates
extension HomeKitManager: HMHomeDelegate {
    /// Called when an accessory is added to the home
    ///
    /// **Performance**: Uses incremental update instead of full reload
    ///
    /// - Parameters:
    ///   - home: The home that changed
    ///   - accessory: The accessory that was added
    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Insert in sorted position
            if let insertIndex = self.accessories.firstIndex(where: { $0.name > accessory.name }) {
                self.accessories.insert(accessory, at: insertIndex)
            } else {
                self.accessories.append(accessory)
            }
            self.statusMessage = "Added: \(accessory.name)"
        }
    }

    /// Called when an accessory is removed from the home
    ///
    /// **Performance**: Uses incremental update instead of full reload
    ///
    /// - Parameters:
    ///   - home: The home that changed
    ///   - accessory: The accessory that was removed
    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.accessories.removeAll { $0.uniqueIdentifier == accessory.uniqueIdentifier }
            self.statusMessage = "Removed: \(accessory.name)"
        }
    }

    /// Called when a room is added to the home
    ///
    /// **Performance**: Uses incremental update instead of full reload
    ///
    /// - Parameters:
    ///   - home: The home that changed
    ///   - room: The room that was added
    func home(_ home: HMHome, didAdd room: HMRoom) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            // Insert in sorted position
            if let insertIndex = self.rooms.firstIndex(where: { $0.name > room.name }) {
                self.rooms.insert(room, at: insertIndex)
            } else {
                self.rooms.append(room)
            }
            self.statusMessage = "Added room: \(room.name)"
        }
    }

    /// Called when a room is removed from the home
    ///
    /// **Performance**: Uses incremental update instead of full reload
    ///
    /// - Parameters:
    ///   - home: The home that changed
    ///   - room: The room that was removed
    func home(_ home: HMHome, didRemove room: HMRoom) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.rooms.removeAll { $0.uniqueIdentifier == room.uniqueIdentifier }
            self.statusMessage = "Removed room: \(room.name)"
        }
    }

    /// Called when an accessory's reachability changes
    ///
    /// **Performance**: Updates single accessory instead of full reload
    ///
    /// - Parameters:
    ///   - home: The home that changed
    ///   - accessory: The accessory whose reachability changed
    func home(_ home: HMHome, didUpdate accessory: HMAccessory) {
        Task { @MainActor [weak self] in
            await self?.updateAccessory(accessory)
        }
    }
}
