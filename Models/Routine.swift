import Foundation
import HomeKit

/// Action type for routines
///
/// Defines different types of actions that can be performed in a routine.
enum RoutineActionType: String, Codable {
    case executeScene
    case setAccessoryState
    case wait
    case conditional
    case notification
}

/// Routine action
///
/// Represents a single action within a routine sequence.
struct RoutineAction: Identifiable, Codable {
    /// Unique identifier
    let id: UUID

    /// Type of action
    let type: RoutineActionType

    /// Target UUID (scene, accessory, etc.)
    var targetID: UUID?

    /// Action-specific parameters
    var parameters: [String: String]

    /// Wait duration (for wait actions)
    var waitDuration: TimeInterval

    /// Order in the sequence
    var order: Int

    /// Initialize a new routine action
    init(type: RoutineActionType, targetID: UUID? = nil, parameters: [String: String] = [:], waitDuration: TimeInterval = 0, order: Int = 0) {
        self.id = UUID()
        self.type = type
        self.targetID = targetID
        self.parameters = parameters
        self.waitDuration = waitDuration
        self.order = order
    }
}

/// Routine trigger condition
///
/// Defines when a routine should execute automatically.
enum RoutineTrigger: String, Codable {
    case manual          // User-triggered only
    case timeOfDay       // Specific time
    case sunrise         // At sunrise
    case sunset          // At sunset
    case arriveHome      // When arriving home
    case leaveHome       // When leaving home
    case accessoryState  // When accessory changes state
}

/// Smart home routine
///
/// A routine is a sequence of actions that execute in order.
/// Can be triggered manually or automatically based on conditions.
///
/// **Examples**:
/// - Morning routine: Gradually turn on lights, adjust thermostat
/// - Bedtime routine: Lock doors, turn off lights, arm security
/// - Movie mode: Dim lights, close blinds, adjust audio
///
/// **Features**:
/// - Sequential actions with delays
/// - Conditional logic
/// - Automatic triggers
/// - Manual execution
struct Routine: Identifiable, Codable {
    /// Unique identifier
    let id: UUID

    /// Display name
    var name: String

    /// Description
    var description: String

    /// Icon name (SF Symbol)
    var iconName: String

    /// Color identifier
    var colorName: String

    /// Array of actions to perform
    var actions: [RoutineAction]

    /// Trigger type
    var trigger: RoutineTrigger

    /// Trigger time (for timeOfDay trigger)
    var triggerTime: Date?

    /// Whether routine is enabled
    var isEnabled: Bool

    /// Days of week (1=Sunday, 7=Saturday)
    var activeDays: Set<Int>

    /// Last execution date
    var lastExecuted: Date?

    /// Execution count
    var executionCount: Int

    /// Created date
    let createdAt: Date

    /// Modified date
    var modifiedAt: Date

    /// Initialize a new routine
    init(name: String, description: String = "", iconName: String = "sparkles", colorName: String = "purple", actions: [RoutineAction] = [], trigger: RoutineTrigger = .manual) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.iconName = iconName
        self.colorName = colorName
        self.actions = actions.sorted { $0.order < $1.order }
        self.trigger = trigger
        self.isEnabled = true
        self.activeDays = Set(1...7) // All days
        self.executionCount = 0
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

/// Routine manager
///
/// Manages creation, execution, and scheduling of routines.
///
/// **Thread Safety**: All UI updates on main thread
/// **Memory Management**: Weak references to avoid retain cycles
class RoutineManager: ObservableObject {
    /// Published array of all routines
    @Published var routines: [Routine] = []

    /// Currently executing routine
    @Published var executingRoutine: Routine?

    /// Execution progress (0.0 - 1.0)
    @Published var executionProgress: Double = 0

    /// UserDefaults key
    private let routinesKey = "com.homekittv.routines"

    /// Timer for scheduled routines
    private var schedulerTimer: Timer?

    /// Singleton instance
    static let shared = RoutineManager()

    /// Private initializer
    private init() {
        loadRoutines()
        startScheduler()
    }

    deinit {
        schedulerTimer?.invalidate()
    }

    // MARK: - Data Management

    /// Load routines from storage
    private func loadRoutines() {
        guard let data = UserDefaults.standard.data(forKey: routinesKey) else {
            routines = createDefaultRoutines()
            saveRoutines()
            return
        }

        do {
            routines = try JSONDecoder().decode([Routine].self, from: data)
        } catch {
            routines = createDefaultRoutines()
        }
    }

    /// Save routines to storage
    private func saveRoutines() {
        do {
            let data = try JSONEncoder().encode(routines)
            UserDefaults.standard.set(data, forKey: routinesKey)
        } catch {
        }
    }

    /// Create default routines for new users
    private func createDefaultRoutines() -> [Routine] {
        var routines: [Routine] = []

        // Good Morning Routine
        var morningRoutine = Routine(
            name: "Good Morning",
            description: "Start your day right",
            iconName: "sun.max.fill",
            colorName: "yellow",
            trigger: .timeOfDay
        )
        morningRoutine.triggerTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0))
        routines.append(morningRoutine)

        // Good Night Routine
        var nightRoutine = Routine(
            name: "Good Night",
            description: "Secure your home for sleep",
            iconName: "moon.stars.fill",
            colorName: "indigo",
            trigger: .timeOfDay
        )
        nightRoutine.triggerTime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0))
        routines.append(nightRoutine)

        // Leave Home Routine
        let leaveRoutine = Routine(
            name: "Leave Home",
            description: "Secure your home when leaving",
            iconName: "arrow.right.circle.fill",
            colorName: "orange",
            trigger: .leaveHome
        )
        routines.append(leaveRoutine)

        // Arrive Home Routine
        let arriveRoutine = Routine(
            name: "Arrive Home",
            description: "Welcome home automation",
            iconName: "house.fill",
            colorName: "green",
            trigger: .arriveHome
        )
        routines.append(arriveRoutine)

        // Movie Time Routine
        let movieRoutine = Routine(
            name: "Movie Time",
            description: "Perfect cinema atmosphere",
            iconName: "film.fill",
            colorName: "purple"
        )
        routines.append(movieRoutine)

        return routines
    }

    // MARK: - Routine Management

    /// Create a new routine
    func createRoutine(name: String, description: String, iconName: String, colorName: String, trigger: RoutineTrigger) -> Routine {
        let routine = Routine(name: name, description: description, iconName: iconName, colorName: colorName, trigger: trigger)
        routines.append(routine)
        saveRoutines()
        return routine
    }

    /// Update an existing routine
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            var updated = routine
            updated.modifiedAt = Date()
            routines[index] = updated
            saveRoutines()
        }
    }

    /// Delete a routine
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }

    /// Add action to routine
    func addAction(to routine: Routine, action: RoutineAction) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            var updated = routine
            var newAction = action
            newAction.order = updated.actions.count
            updated.actions.append(newAction)
            updated.actions.sort { $0.order < $1.order }
            routines[index] = updated
            saveRoutines()
        }
    }

    /// Remove action from routine
    func removeAction(from routine: Routine, action: RoutineAction) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            var updated = routine
            updated.actions.removeAll { $0.id == action.id }
            // Reorder remaining actions
            updated.actions = updated.actions.enumerated().map { index, action in
                var updatedAction = action
                updatedAction.order = index
                return updatedAction
            }
            routines[index] = updated
            saveRoutines()
        }
    }

    // MARK: - Execution

    /// Execute a routine
    ///
    /// Runs all actions in the routine sequentially.
    ///
    /// - Parameters:
    ///   - routine: The routine to execute
    ///   - homeManager: HomeKitManager instance for controlling accessories
    ///   - completion: Called when execution completes or fails
    func executeRoutine(_ routine: Routine, homeManager: HomeKitManager, completion: @escaping (Bool, Error?) -> Void) {
        guard routine.isEnabled else {
            completion(false, NSError(domain: "RoutineManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Routine is disabled"]))
            return
        }

        DispatchQueue.main.async {
            self.executingRoutine = routine
            self.executionProgress = 0
        }

        let actions = routine.actions.sorted { $0.order < $1.order }
        executeActions(actions, index: 0, homeManager: homeManager) { success, error in
            DispatchQueue.main.async {
                self.executingRoutine = nil
                self.executionProgress = 0

                if success {
                    // Update execution stats
                    if let index = self.routines.firstIndex(where: { $0.id == routine.id }) {
                        self.routines[index].lastExecuted = Date()
                        self.routines[index].executionCount += 1
                        self.saveRoutines()
                    }
                }

                completion(success, error)
            }
        }
    }

    /// Execute actions recursively
    private func executeActions(_ actions: [RoutineAction], index: Int, homeManager: HomeKitManager, completion: @escaping (Bool, Error?) -> Void) {
        guard index < actions.count else {
            completion(true, nil)
            return
        }

        let action = actions[index]
        let progress = Double(index) / Double(actions.count)

        DispatchQueue.main.async {
            self.executionProgress = progress
        }

        switch action.type {
        case .executeScene:
            if let sceneID = action.targetID,
               let scene = homeManager.scenes.first(where: { $0.uniqueIdentifier == sceneID }) {
                homeManager.executeScene(scene)
                // Wait a bit for scene to execute
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.executeActions(actions, index: index + 1, homeManager: homeManager, completion: completion)
                }
            } else {
                executeActions(actions, index: index + 1, homeManager: homeManager, completion: completion)
            }

        case .wait:
            DispatchQueue.main.asyncAfter(deadline: .now() + action.waitDuration) {
                self.executeActions(actions, index: index + 1, homeManager: homeManager, completion: completion)
            }

        case .setAccessoryState:
            // Implementation would control specific accessory
            executeActions(actions, index: index + 1, homeManager: homeManager, completion: completion)

        default:
            executeActions(actions, index: index + 1, homeManager: homeManager, completion: completion)
        }
    }

    // MARK: - Scheduling

    /// Start the scheduler for automatic routine execution
    private func startScheduler() {
        schedulerTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkScheduledRoutines()
        }
    }

    /// Check if any routines should execute now
    private func checkScheduledRoutines() {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentWeekday = calendar.component(.weekday, from: now)

        for routine in routines where routine.isEnabled {
            guard routine.trigger == .timeOfDay,
                  let triggerTime = routine.triggerTime,
                  routine.activeDays.contains(currentWeekday) else {
                continue
            }

            let triggerHour = calendar.component(.hour, from: triggerTime)
            let triggerMinute = calendar.component(.minute, from: triggerTime)

            if currentHour == triggerHour && currentMinute == triggerMinute {
                // Check if already executed today
                if let lastExecuted = routine.lastExecuted,
                   calendar.isDateInToday(lastExecuted) {
                    continue
                }

                // Execute routine (would need HomeKitManager reference)
            }
        }
    }
}
