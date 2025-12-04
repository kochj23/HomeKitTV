import Foundation
import HomeKit

class DeveloperToolsManager: ObservableObject {
    static let shared = DeveloperToolsManager()
    @Published var logs: [DevLog] = []
    @Published var apiRequests: [APIRequest] = []
    
    struct DevLog: Identifiable {
        let id: UUID
        let timestamp: Date
        let level: LogLevel
        let message: String
        
        enum LogLevel {
            case debug, info, warning, error
        }
    }
    
    struct APIRequest: Identifiable {
        let id: UUID
        let timestamp: Date
        let endpoint: String
        let method: String
        let responseTime: TimeInterval
        let statusCode: Int
    }
    
    func log(_ message: String, level: DevLog.LogLevel = .info) {
        let log = DevLog(
            id: UUID(),
            timestamp: Date(),
            level: level,
            message: message
        )
        logs.append(log)
    }
    
    func inspectCharacteristic(_ characteristic: HMCharacteristic) -> [String: Any] {
        return [
            "type": characteristic.characteristicType,
            "value": characteristic.value ?? "nil",
            "readable": characteristic.properties.contains(.readable),
            "writable": characteristic.properties.contains(.writable),
            "notifies": characteristic.properties.contains(.supportsEventNotification)
        ]
    }
}