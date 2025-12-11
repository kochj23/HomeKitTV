import Foundation
import HomeKit

class DeviceGroupManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = DeviceGroupManager()
    @Published var groups: [DeviceGroup] = []
    
    struct DeviceGroup: Identifiable, Codable {
        let id: UUID
        var name: String
        var deviceIDs: [String]
        var icon: String
    }
    
    func createGroup(name: String, devices: [HMAccessory]) {
        let group = DeviceGroup(
            id: UUID(),
            name: name,
            deviceIDs: devices.map { $0.uniqueIdentifier.uuidString },
            icon: "folder.fill"
        )
        groups.append(group)
    }
}
