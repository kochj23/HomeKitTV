import Foundation
import HomeKit

/// Service group manager for custom accessory grouping
///
/// Allows users to create custom groups of accessories beyond room-based organization.
/// Examples: "All First Floor Lights", "All Outdoor Devices", "All Locks"
///
/// **Features**:
/// - Custom group creation
/// - Bulk operations on groups
/// - Persistent storage
/// - Smart grouping suggestions
class ServiceGroupManager: ObservableObject {
    static let shared = ServiceGroupManager()

    @Published var serviceGroups: [ServiceGroup] = []

    private let groupsKey = "com.homekittv.serviceGroups"

    private init() {
        loadGroups()
    }

    // MARK: - Group Management

    /// Create a new service group
    func createGroup(name: String, icon: String, color: String, accessoryIDs: Set<String>) {
        let group = ServiceGroup(name: name, icon: icon, color: color, accessoryIDs: accessoryIDs)
        serviceGroups.append(group)
        serviceGroups.sort { $0.name < $1.name }
        saveGroups()
    }

    /// Update an existing group
    func updateGroup(_ group: ServiceGroup, name: String, icon: String, color: String, accessoryIDs: Set<String>) {
        if let index = serviceGroups.firstIndex(where: { $0.id == group.id }) {
            serviceGroups[index].name = name
            serviceGroups[index].icon = icon
            serviceGroups[index].color = color
            serviceGroups[index].accessoryIDs = accessoryIDs
            saveGroups()
        }
    }

    /// Delete a group
    func deleteGroup(_ group: ServiceGroup) {
        serviceGroups.removeAll { $0.id == group.id }
        saveGroups()
    }

    /// Get accessories for a group
    func accessories(for group: ServiceGroup, from homeManager: HomeKitManager) -> [HMAccessory] {
        homeManager.accessories.filter { group.accessoryIDs.contains($0.uniqueIdentifier.uuidString) }
    }

    /// Check if accessory is in group
    func isInGroup(_ accessory: HMAccessory, group: ServiceGroup) -> Bool {
        group.accessoryIDs.contains(accessory.uniqueIdentifier.uuidString)
    }

    // MARK: - Smart Suggestions

    /// Generate smart group suggestions based on naming patterns and types
    func generateSuggestions(from accessories: [HMAccessory]) -> [ServiceGroup] {
        var suggestions: [ServiceGroup] = []

        // All Lights
        let lightIDs = Set(accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLightbulb } }
            .map { $0.uniqueIdentifier.uuidString })
        if !lightIDs.isEmpty {
            suggestions.append(ServiceGroup(name: "All Lights", icon: "lightbulb.fill", color: "yellow", accessoryIDs: lightIDs))
        }

        // All Locks
        let lockIDs = Set(accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeLockMechanism } }
            .map { $0.uniqueIdentifier.uuidString })
        if !lockIDs.isEmpty {
            suggestions.append(ServiceGroup(name: "All Locks", icon: "lock.fill", color: "green", accessoryIDs: lockIDs))
        }

        // All Fans
        let fanIDs = Set(accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeFan } }
            .map { $0.uniqueIdentifier.uuidString })
        if !fanIDs.isEmpty {
            suggestions.append(ServiceGroup(name: "All Fans", icon: "fan.fill", color: "cyan", accessoryIDs: fanIDs))
        }

        // All Thermostats
        let thermostatIDs = Set(accessories.filter { $0.services.contains { $0.serviceType == HMServiceTypeThermostat } }
            .map { $0.uniqueIdentifier.uuidString })
        if !thermostatIDs.isEmpty {
            suggestions.append(ServiceGroup(name: "All Thermostats", icon: "thermometer", color: "orange", accessoryIDs: thermostatIDs))
        }

        // Outdoor devices (based on room name)
        let outdoorIDs = Set(accessories.filter { accessory in
            let roomName = accessory.room?.name.lowercased() ?? ""
            return roomName.contains("outdoor") || roomName.contains("outside") ||
                   roomName.contains("patio") || roomName.contains("deck") ||
                   roomName.contains("yard") || roomName.contains("garden")
        }.map { $0.uniqueIdentifier.uuidString })
        if !outdoorIDs.isEmpty {
            suggestions.append(ServiceGroup(name: "Outdoor Devices", icon: "sun.max.fill", color: "orange", accessoryIDs: outdoorIDs))
        }

        // Floor-based groups (if floor names exist)
        let floors = Set(accessories.compactMap { accessory -> String? in
            let roomName = accessory.room?.name.lowercased() ?? ""
            if roomName.contains("first") || roomName.contains("1st") {
                return "First Floor"
            } else if roomName.contains("second") || roomName.contains("2nd") {
                return "Second Floor"
            } else if roomName.contains("basement") {
                return "Basement"
            }
            return nil
        })

        for floor in floors {
            let floorIDs = Set(accessories.filter { accessory in
                let roomName = accessory.room?.name.lowercased() ?? ""
                if floor == "First Floor" {
                    return roomName.contains("first") || roomName.contains("1st")
                } else if floor == "Second Floor" {
                    return roomName.contains("second") || roomName.contains("2nd")
                } else if floor == "Basement" {
                    return roomName.contains("basement")
                }
                return false
            }.map { $0.uniqueIdentifier.uuidString })

            if !floorIDs.isEmpty {
                suggestions.append(ServiceGroup(name: floor, icon: "building.2.fill", color: "blue", accessoryIDs: floorIDs))
            }
        }

        return suggestions
    }

    // MARK: - Bulk Operations

    /// Turn on all accessories in a group
    func turnOnAll(group: ServiceGroup, homeManager: HomeKitManager) {
        let accessories = self.accessories(for: group, from: homeManager)
        for accessory in accessories {
            if !homeManager.getPowerState(accessory) {
                homeManager.toggleAccessory(accessory)
            }
        }
    }

    /// Turn off all accessories in a group
    func turnOffAll(group: ServiceGroup, homeManager: HomeKitManager) {
        let accessories = self.accessories(for: group, from: homeManager)
        for accessory in accessories {
            if homeManager.getPowerState(accessory) {
                homeManager.toggleAccessory(accessory)
            }
        }
    }

    // MARK: - Persistence

    private func loadGroups() {
        if let data = UserDefaults.standard.data(forKey: groupsKey),
           let groups = try? JSONDecoder().decode([ServiceGroup].self, from: data) {
            serviceGroups = groups
        }
    }

    private func saveGroups() {
        if let data = try? JSONEncoder().encode(serviceGroups) {
            UserDefaults.standard.set(data, forKey: groupsKey)
        }
    }
}

// MARK: - Models

/// Service group model
struct ServiceGroup: Identifiable, Codable {
    let id: UUID
    var name: String
    var icon: String
    var color: String
    var accessoryIDs: Set<String>
    var createdAt: Date

    init(name: String, icon: String, color: String, accessoryIDs: Set<String>) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.accessoryIDs = accessoryIDs
        self.createdAt = Date()
    }
}
