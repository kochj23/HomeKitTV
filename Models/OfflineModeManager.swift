import Foundation
import HomeKit
import Network

// MARK: - Offline Mode Manager

/// Manages offline mode and command queuing
///
/// Handles network connectivity monitoring and queues failed commands for retry
/// when connection is restored.
///
/// **Features**:
/// - Network connectivity monitoring
/// - Command queue for failed operations
/// - Automatic retry when online
/// - Last known state caching
///
/// **Author**: Jordan Koch
class OfflineModeManager: ObservableObject {
    static let shared = OfflineModeManager()

    // MARK: - Published Properties

    @Published var isOnline: Bool = true
    @Published var lastSyncTime: Date?
    @Published var queuedCommands: [PendingCommand] = []
    @Published var cachedState: [UUID: AccessoryState] = [:]

    // MARK: - Private Properties

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.homekittv.networkmonitor")
    private let maxQueueSize = 50
    private let commandTimeout: TimeInterval = 30.0

    // MARK: - Initialization

    private init() {
        startNetworkMonitoring()
        loadCachedState()
    }

    /// Cleans up resources
    deinit {
        pathMonitor.cancel()
    }

    // MARK: - Network Monitoring

    /// Starts monitoring network connectivity
    ///
    /// **Performance**: Runs on background queue to avoid blocking main thread
    func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let isOnline = path.status == .satisfied

            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = isOnline

                // If we just came back online, process queue
                if wasOffline && isOnline {
                    Task {
                        await self.processCommandQueue()
                    }
                }
            }
        }

        pathMonitor.start(queue: monitorQueue)
    }

    // MARK: - Command Queue Management

    /// Adds a command to the queue
    ///
    /// **Memory**: Enforces maximum queue size to prevent unbounded growth
    func enqueueCommand(_ command: PendingCommand) {
        queuedCommands.append(command)

        // Enforce queue size limit
        if queuedCommands.count > maxQueueSize {
            queuedCommands.removeFirst()
        }

        saveQueue()
    }

    /// Processes all queued commands
    ///
    /// **Retry Logic**: Attempts each command and removes successful ones from queue
    @MainActor
    func processCommandQueue() async {
        guard isOnline else { return }

        var successfulCommands: [UUID] = []

        for command in queuedCommands {
            do {
                try await executeCommand(command)
                successfulCommands.append(command.id)
            } catch {
                print("⚠️ Queued command failed: \(error.localizedDescription)")
                // Keep in queue for next attempt
            }
        }

        // Remove successful commands
        queuedCommands.removeAll { successfulCommands.contains($0.id) }
        saveQueue()

        if !successfulCommands.isEmpty {
            lastSyncTime = Date()
        }
    }

    /// Executes a pending command
    private func executeCommand(_ command: PendingCommand) async throws {
        // Check if command is too old
        let age = Date().timeIntervalSince(command.timestamp)
        if age > commandTimeout {
            throw HomeKitError.operationTimeout
        }

        // Execute based on type
        switch command.type {
        case .toggleAccessory(let accessory):
            // Would need reference to HomeKitManager to execute
            // For now, this is a placeholder
            print("Executing queued toggle for \(accessory.name)")

        case .executeScene(let scene):
            print("Executing queued scene: \(scene.name)")

        case .setValue(let accessory, let characteristic, let value):
            print("Executing queued setValue for \(accessory.name)")
        }
    }

    // MARK: - State Caching

    /// Caches the current state of an accessory
    func cacheAccessoryState(_ accessory: HMAccessory, powerState: Bool) {
        let state = AccessoryState(
            name: accessory.name,
            powerState: powerState,
            isReachable: accessory.isReachable,
            lastUpdated: Date()
        )

        cachedState[accessory.uniqueIdentifier] = state
        saveCachedState()
    }

    /// Gets cached state for an accessory
    func getCachedState(for accessory: HMAccessory) -> AccessoryState? {
        return cachedState[accessory.uniqueIdentifier]
    }

    // MARK: - Persistence

    private func saveQueue() {
        if let encoded = try? JSONEncoder().encode(queuedCommands) {
            UserDefaults.standard.set(encoded, forKey: "offlineCommandQueue")
        }
    }

    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: "offlineCommandQueue"),
           let commands = try? JSONDecoder().decode([PendingCommand].self, from: data) {
            queuedCommands = commands
        }
    }

    private func saveCachedState() {
        // Save cached state for offline viewing
        let stateDict = cachedState.mapValues { state in
            [
                "name": state.name,
                "powerState": state.powerState,
                "isReachable": state.isReachable,
                "lastUpdated": state.lastUpdated.timeIntervalSince1970
            ] as [String: Any]
        }

        if let data = try? JSONSerialization.data(withJSONObject: stateDict) {
            UserDefaults.standard.set(data, forKey: "cachedAccessoryState")
        }
    }

    private func loadCachedState() {
        loadQueue()

        // Load cached state
        guard let data = UserDefaults.standard.data(forKey: "cachedAccessoryState"),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else {
            return
        }

        var loadedState: [UUID: AccessoryState] = [:]
        for (uuidString, stateDict) in dict {
            guard let uuid = UUID(uuidString: uuidString),
                  let name = stateDict["name"] as? String,
                  let powerState = stateDict["powerState"] as? Bool,
                  let isReachable = stateDict["isReachable"] as? Bool,
                  let timestamp = stateDict["lastUpdated"] as? TimeInterval else {
                continue
            }

            loadedState[uuid] = AccessoryState(
                name: name,
                powerState: powerState,
                isReachable: isReachable,
                lastUpdated: Date(timeIntervalSince1970: timestamp)
            )
        }

        cachedState = loadedState
    }

    // MARK: - Status

    /// Get relative time string for last sync
    func relativeSyncTime() -> String? {
        guard let lastSync = lastSyncTime else { return nil }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSync, relativeTo: Date())
    }
}

// MARK: - Pending Command

/// Represents a command waiting to be executed
struct PendingCommand: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: CommandType

    enum CommandType: Codable {
        case toggleAccessory(name: String, id: String)
        case executeScene(name: String, id: String)
        case setValue(accessoryName: String, accessoryID: String, characteristic: String, value: String)
    }

    init(type: CommandType) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
    }

    /// Age of command in seconds
    var age: TimeInterval {
        Date().timeIntervalSince(timestamp)
    }

    /// Human-readable description
    var description: String {
        switch type {
        case .toggleAccessory(let name, _):
            return "Toggle \(name)"
        case .executeScene(let name, _):
            return "Execute scene: \(name)"
        case .setValue(let name, _, let char, let val):
            return "Set \(char) to \(val) for \(name)"
        }
    }
}

// MARK: - Accessory State

/// Cached state of an accessory for offline viewing
struct AccessoryState {
    let name: String
    let powerState: Bool
    let isReachable: Bool
    let lastUpdated: Date

    /// How old is this cached state?
    var age: TimeInterval {
        Date().timeIntervalSince(lastUpdated)
    }

    /// Is this state stale? (older than 5 minutes)
    var isStale: Bool {
        age > 300
    }
}
