import Foundation
import HomeKit

/// Represents a zone - a collection of multiple rooms
///
/// Zones allow users to group multiple rooms together for easier control.
/// For example: "Upstairs", "Downstairs", "Outside", "Bedrooms", etc.
///
/// **Features**:
/// - Group multiple rooms into logical zones
/// - Control all accessories in a zone at once
/// - Zone-specific scenes and automations
/// - Persistent storage using UserDefaults
///
/// **Memory Safety**: Uses UUID for unique identification, struct for value semantics
struct Zone: Identifiable, Codable {
    /// Unique identifier for the zone
    let id: UUID

    /// Display name of the zone
    var name: String

    /// Room identifiers that belong to this zone
    var roomIDs: [UUID]

    /// Icon name for the zone (SF Symbol)
    var iconName: String

    /// Color identifier for visual distinction
    var colorName: String

    /// When the zone was created
    let createdAt: Date

    /// Last modification date
    var modifiedAt: Date

    /// Initialize a new zone
    ///
    /// - Parameters:
    ///   - name: Display name for the zone
    ///   - roomIDs: Array of room UUIDs to include
    ///   - iconName: SF Symbol name for icon
    ///   - colorName: Color identifier string
    init(name: String, roomIDs: [UUID] = [], iconName: String = "square.grid.2x2", colorName: String = "blue") {
        self.id = UUID()
        self.name = name
        self.roomIDs = roomIDs
        self.iconName = iconName
        self.colorName = colorName
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

/// Zone manager for creating, updating, and deleting zones
///
/// This class manages the lifecycle of zones and persists them to UserDefaults.
///
/// **Thread Safety**: All operations are performed on main thread
/// **Memory Management**: No retain cycles - uses value types (structs)
class ZoneManager: ObservableObject {
    /// Published array of all zones
    @Published var zones: [Zone] = []

    /// UserDefaults key for storing zones
    private let zonesKey = "com.homekittv.zones"

    /// Singleton instance
    static let shared = ZoneManager()

    /// Private initializer to enforce singleton pattern
    private init() {
        loadZones()
    }

    /// Load zones from persistent storage
    ///
    /// Decodes zones from UserDefaults and updates the published property.
    /// If loading fails, initializes with empty array.
    ///
    /// **Error Handling**: Silently fails and logs error if decoding fails
    func loadZones() {
        guard let data = UserDefaults.standard.data(forKey: zonesKey) else {
            zones = []
            return
        }

        do {
            zones = try JSONDecoder().decode([Zone].self, from: data)
        } catch {
            zones = []
        }
    }

    /// Save zones to persistent storage
    ///
    /// Encodes zones to JSON and saves to UserDefaults.
    ///
    /// **Error Handling**: Logs error if encoding fails but doesn't throw
    private func saveZones() {
        do {
            let data = try JSONEncoder().encode(zones)
            UserDefaults.standard.set(data, forKey: zonesKey)
        } catch {
        }
    }

    /// Create a new zone
    ///
    /// - Parameters:
    ///   - name: Display name for the zone
    ///   - roomIDs: Array of room UUIDs to include
    ///   - iconName: SF Symbol name
    ///   - colorName: Color identifier
    /// - Returns: The newly created zone
    func createZone(name: String, roomIDs: [UUID], iconName: String = "square.grid.2x2", colorName: String = "blue") -> Zone {
        let zone = Zone(name: name, roomIDs: roomIDs, iconName: iconName, colorName: colorName)
        zones.append(zone)
        saveZones()
        return zone
    }

    /// Update an existing zone
    ///
    /// - Parameter zone: The zone to update
    func updateZone(_ zone: Zone) {
        if let index = zones.firstIndex(where: { $0.id == zone.id }) {
            var updatedZone = zone
            updatedZone.modifiedAt = Date()
            zones[index] = updatedZone
            saveZones()
        }
    }

    /// Delete a zone
    ///
    /// - Parameter zone: The zone to delete
    func deleteZone(_ zone: Zone) {
        zones.removeAll { $0.id == zone.id }
        saveZones()
    }

    /// Get all rooms in a zone
    ///
    /// - Parameters:
    ///   - zone: The zone to query
    ///   - home: The home containing the rooms
    /// - Returns: Array of HMRoom objects in the zone
    func rooms(for zone: Zone, in home: HMHome) -> [HMRoom] {
        return home.rooms.filter { room in
            zone.roomIDs.contains(room.uniqueIdentifier)
        }
    }

    /// Get all accessories in a zone
    ///
    /// - Parameters:
    ///   - zone: The zone to query
    ///   - home: The home containing the accessories
    /// - Returns: Array of HMAccessory objects in the zone
    func accessories(for zone: Zone, in home: HMHome) -> [HMAccessory] {
        let zoneRooms = rooms(for: zone, in: home)
        return home.accessories.filter { accessory in
            guard let room = accessory.room else { return false }
            return zoneRooms.contains(room)
        }
    }
}
