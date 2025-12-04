import Foundation
import HomeKit

class DeviceHealthMonitor: ObservableObject {
    static let shared = DeviceHealthMonitor()
    @Published var healthReports: [String: DeviceHealth] = [:]
    
    struct DeviceHealth {
        let deviceID: String
        var signalStrength: Int
        var batteryLevel: Int?
        var lastSeen: Date
        var connectionStability: Double
        var firmwareVersion: String?
        var issueCount: Int
        
        var healthScore: Int {
            var score = 100
            if signalStrength < 50 { score -= 20 }
            if let battery = batteryLevel, battery < 20 { score -= 30 }
            if connectionStability < 0.8 { score -= 25 }
            return max(0, score)
        }
    }
    
    func monitorDevice(_ accessory: HMAccessory) {
        let health = DeviceHealth(
            deviceID: accessory.uniqueIdentifier.uuidString,
            signalStrength: Int.random(in: 50...100),
            batteryLevel: nil,
            lastSeen: Date(),
            connectionStability: 0.95,
            firmwareVersion: accessory.firmwareVersion,
            issueCount: 0
        )
        healthReports[accessory.uniqueIdentifier.uuidString] = health
    }
}