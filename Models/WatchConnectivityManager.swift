import Foundation
import WatchConnectivity
import HomeKit

/// Manages bidirectional communication between the main app and Apple Watch
///
/// This class handles:
/// - Sending favorite scenes and accessories to the watch
/// - Receiving commands from the watch (scene execution, accessory control)
/// - Keeping watch complications updated
///
/// **Thread Safety**: All HomeKit operations are dispatched appropriately
class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()

    // MARK: - Published Properties

    @Published var isWatchConnected: Bool = false
    @Published var isWatchReachable: Bool = false
    @Published var lastSyncDate: Date?

    // MARK: - Private Properties

    private var session: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    override private init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    /// Cleans up resources to prevent memory leaks
    deinit {
        session?.delegate = nil
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchConnected = activationState == .activated
            self.isWatchReachable = session.isReachable

            if activationState == .activated {
                // Send initial data to watch
                self.syncToWatch()
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session for iOS
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    // MARK: - Receive Messages from Watch

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Handle command from watch
        if let commandData = message[WatchMessageKeys.command] as? Data,
           let command = try? decoder.decode(WatchCommandPayload.self, from: commandData) {
            handleWatchCommand(command, replyHandler: replyHandler)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle message without reply
        if let commandData = message[WatchMessageKeys.command] as? Data,
           let command = try? decoder.decode(WatchCommandPayload.self, from: commandData) {
            handleWatchCommand(command, replyHandler: nil)
        }
    }

    // MARK: - Send Data to Watch

    /// Send full sync of favorites to watch
    func syncToWatch() {
        guard let session = session, session.activationState == .activated else { return }

        let homeData = createHomeData()

        do {
            let data = try encoder.encode(homeData)
            let message: [String: Any] = [WatchMessageKeys.homeData: data]

            if session.isReachable {
                session.sendMessage(message, replyHandler: nil, errorHandler: { error in
                    print("Watch sync error: \(error.localizedDescription)")
                })
            } else {
                // Use application context for background delivery
                try session.updateApplicationContext(message)
            }

            DispatchQueue.main.async {
                self.lastSyncDate = Date()
            }
        } catch {
            print("Failed to encode watch data: \(error)")
        }
    }

    /// Send single accessory state update
    func sendAccessoryUpdate(_ accessory: HMAccessory) {
        guard let session = session, session.isReachable else { return }

        let watchAccessory = createWatchAccessory(from: accessory)

        do {
            let data = try encoder.encode(watchAccessory)
            let message: [String: Any] = [WatchMessageKeys.accessoryUpdate: data]
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        } catch {
            print("Failed to send accessory update: \(error)")
        }
    }

    /// Notify watch that a scene was executed
    func notifySceneExecuted(_ scene: HMActionSet) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [WatchMessageKeys.sceneExecuted: scene.uniqueIdentifier.uuidString]
        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    /// Legacy method for backwards compatibility
    func sendToWatch(_ data: [String: Any]) {
        session?.sendMessage(data, replyHandler: nil)
    }

    // MARK: - Handle Watch Commands

    private func handleWatchCommand(_ command: WatchCommandPayload, replyHandler: (([String: Any]) -> Void)?) {
        switch command.command {
        case .refreshData:
            syncToWatch()
            sendResponse(success: true, message: "Data synced", replyHandler: replyHandler)

        case .executeScene:
            guard let sceneId = command.targetId else {
                sendResponse(success: false, message: "No scene ID", replyHandler: replyHandler)
                return
            }
            executeScene(id: sceneId, replyHandler: replyHandler)

        case .toggleAccessory:
            guard let accessoryId = command.targetId else {
                sendResponse(success: false, message: "No accessory ID", replyHandler: replyHandler)
                return
            }
            toggleAccessory(id: accessoryId, replyHandler: replyHandler)

        case .setAccessoryBrightness:
            guard let accessoryId = command.targetId, let brightness = command.value else {
                sendResponse(success: false, message: "Invalid parameters", replyHandler: replyHandler)
                return
            }
            setAccessoryBrightness(id: accessoryId, brightness: Int(brightness), replyHandler: replyHandler)

        case .setThermostatTemperature:
            guard let accessoryId = command.targetId, let temp = command.value else {
                sendResponse(success: false, message: "Invalid parameters", replyHandler: replyHandler)
                return
            }
            setThermostatTemperature(id: accessoryId, temperature: temp, replyHandler: replyHandler)
        }
    }

    // MARK: - HomeKit Operations

    private func executeScene(id: String, replyHandler: (([String: Any]) -> Void)?) {
        guard let uuid = UUID(uuidString: id),
              let home = HomeKitManager.shared.currentHome,
              let scene = home.actionSets.first(where: { $0.uniqueIdentifier == uuid }) else {
            sendResponse(success: false, message: "Scene not found", replyHandler: replyHandler)
            return
        }

        home.executeActionSet(scene) { [weak self] error in
            if let error = error {
                self?.sendResponse(success: false, message: error.localizedDescription, replyHandler: replyHandler)
            } else {
                self?.sendResponse(success: true, message: "Scene executed", replyHandler: replyHandler)
                self?.notifySceneExecuted(scene)
            }
        }
    }

    private func toggleAccessory(id: String, replyHandler: (([String: Any]) -> Void)?) {
        guard let uuid = UUID(uuidString: id),
              let accessory = HomeKitManager.shared.accessories.first(where: { $0.uniqueIdentifier == uuid }) else {
            sendResponse(success: false, message: "Accessory not found", replyHandler: replyHandler)
            return
        }

        // Find power characteristic
        guard let powerService = accessory.services.first(where: {
            $0.serviceType == HMServiceTypeLightbulb ||
            $0.serviceType == HMServiceTypeOutlet ||
            $0.serviceType == HMServiceTypeSwitch ||
            $0.serviceType == HMServiceTypeFan
        }),
        let powerChar = powerService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) else {
            sendResponse(success: false, message: "No power control", replyHandler: replyHandler)
            return
        }

        let currentValue = (powerChar.value as? Bool) ?? false
        let newValue = !currentValue

        powerChar.writeValue(newValue) { [weak self] error in
            if let error = error {
                self?.sendResponse(success: false, message: error.localizedDescription, replyHandler: replyHandler)
            } else {
                let updatedAccessory = self?.createWatchAccessory(from: accessory)
                self?.sendResponse(success: true, message: nil, accessory: updatedAccessory, replyHandler: replyHandler)
            }
        }
    }

    private func setAccessoryBrightness(id: String, brightness: Int, replyHandler: (([String: Any]) -> Void)?) {
        guard let uuid = UUID(uuidString: id),
              let accessory = HomeKitManager.shared.accessories.first(where: { $0.uniqueIdentifier == uuid }) else {
            sendResponse(success: false, message: "Accessory not found", replyHandler: replyHandler)
            return
        }

        guard let lightService = accessory.services.first(where: { $0.serviceType == HMServiceTypeLightbulb }),
              let brightnessChar = lightService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) else {
            sendResponse(success: false, message: "No brightness control", replyHandler: replyHandler)
            return
        }

        brightnessChar.writeValue(brightness) { [weak self] error in
            if let error = error {
                self?.sendResponse(success: false, message: error.localizedDescription, replyHandler: replyHandler)
            } else {
                let updatedAccessory = self?.createWatchAccessory(from: accessory)
                self?.sendResponse(success: true, message: nil, accessory: updatedAccessory, replyHandler: replyHandler)
            }
        }
    }

    private func setThermostatTemperature(id: String, temperature: Double, replyHandler: (([String: Any]) -> Void)?) {
        guard let uuid = UUID(uuidString: id),
              let accessory = HomeKitManager.shared.accessories.first(where: { $0.uniqueIdentifier == uuid }) else {
            sendResponse(success: false, message: "Accessory not found", replyHandler: replyHandler)
            return
        }

        guard let thermoService = accessory.services.first(where: { $0.serviceType == HMServiceTypeThermostat }),
              let tempChar = thermoService.characteristics.first(where: { $0.characteristicType == HMCharacteristicTypeTargetTemperature }) else {
            sendResponse(success: false, message: "No temperature control", replyHandler: replyHandler)
            return
        }

        tempChar.writeValue(temperature) { [weak self] error in
            if let error = error {
                self?.sendResponse(success: false, message: error.localizedDescription, replyHandler: replyHandler)
            } else {
                let updatedAccessory = self?.createWatchAccessory(from: accessory)
                self?.sendResponse(success: true, message: nil, accessory: updatedAccessory, replyHandler: replyHandler)
            }
        }
    }

    // MARK: - Response Helpers

    private func sendResponse(success: Bool, message: String?, accessory: WatchAccessory? = nil, replyHandler: (([String: Any]) -> Void)?) {
        guard let replyHandler = replyHandler else { return }

        let response = WatchCommandResponse(success: success, message: message, updatedAccessory: accessory)

        do {
            let data = try encoder.encode(response)
            replyHandler([WatchMessageKeys.response: data])
        } catch {
            replyHandler([WatchMessageKeys.response: Data()])
        }
    }

    // MARK: - Data Creation Helpers

    private func createHomeData() -> WatchHomeData {
        let settings = Settings.shared
        let homeKit = HomeKitManager.shared

        let favoriteScenes = homeKit.scenes
            .filter { settings.favoriteSceneIDs.contains($0.uniqueIdentifier.uuidString) }
            .map { createWatchScene(from: $0) }

        let favoriteAccessories = homeKit.accessories
            .filter { settings.favoriteAccessoryIDs.contains($0.uniqueIdentifier.uuidString) }
            .map { createWatchAccessory(from: $0) }

        let rooms = homeKit.rooms.map { createWatchRoom(from: $0) }

        return WatchHomeData(
            homeName: homeKit.currentHome?.name ?? "Home",
            favoriteScenes: favoriteScenes,
            favoriteAccessories: favoriteAccessories,
            rooms: rooms
        )
    }

    private func createWatchScene(from scene: HMActionSet) -> WatchScene {
        WatchScene(
            id: scene.uniqueIdentifier.uuidString,
            name: scene.name,
            iconName: iconForScene(scene),
            accessoryCount: scene.actions.count,
            isFavorite: true
        )
    }

    private func createWatchAccessory(from accessory: HMAccessory) -> WatchAccessory {
        var isOn: Bool?
        var brightness: Int?
        var temperature: Double?

        // Get power state
        if let powerChar = accessory.services
            .flatMap({ $0.characteristics })
            .first(where: { $0.characteristicType == HMCharacteristicTypePowerState }) {
            isOn = powerChar.value as? Bool
        }

        // Get brightness
        if let brightnessChar = accessory.services
            .flatMap({ $0.characteristics })
            .first(where: { $0.characteristicType == HMCharacteristicTypeBrightness }) {
            brightness = brightnessChar.value as? Int
        }

        // Get temperature
        if let tempChar = accessory.services
            .flatMap({ $0.characteristics })
            .first(where: { $0.characteristicType == HMCharacteristicTypeCurrentTemperature }) {
            temperature = tempChar.value as? Double
        }

        return WatchAccessory(
            id: accessory.uniqueIdentifier.uuidString,
            name: accessory.name,
            roomName: accessory.room?.name,
            categoryType: categoryType(for: accessory),
            isReachable: accessory.isReachable,
            isFavorite: true,
            isOn: isOn,
            brightness: brightness,
            temperature: temperature
        )
    }

    private func createWatchRoom(from room: HMRoom) -> WatchRoom {
        WatchRoom(
            id: room.uniqueIdentifier.uuidString,
            name: room.name,
            accessoryCount: room.accessories.count
        )
    }

    private func categoryType(for accessory: HMAccessory) -> String {
        switch accessory.category.categoryType {
        case HMAccessoryCategoryTypeLightbulb: return "light"
        case HMAccessoryCategoryTypeOutlet: return "outlet"
        case HMAccessoryCategoryTypeSwitch: return "switch"
        case HMAccessoryCategoryTypeThermostat: return "thermostat"
        case HMAccessoryCategoryTypeFan: return "fan"
        case HMAccessoryCategoryTypeDoorLock: return "lock"
        case HMAccessoryCategoryTypeSensor: return "sensor"
        default: return "other"
        }
    }

    private func iconForScene(_ scene: HMActionSet) -> String? {
        // Map scene type to icon
        if scene.actionSetType == HMActionSetTypeSleep {
            return "moon.fill"
        } else if scene.actionSetType == HMActionSetTypeWakeUp {
            return "sunrise.fill"
        } else if scene.actionSetType == HMActionSetTypeHomeDeparture {
            return "figure.walk"
        } else if scene.actionSetType == HMActionSetTypeHomeArrival {
            return "house.fill"
        }
        return "wand.and.stars"
    }
}