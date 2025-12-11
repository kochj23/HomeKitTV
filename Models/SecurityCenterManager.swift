import Foundation
import HomeKit

class SecurityCenterManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = SecurityCenterManager()
    @Published var securityStatus: SecurityStatus = .disarmed
    @Published var events: [SecurityEvent] = []
    
    enum SecurityStatus {
        case armed, disarmed, triggered, stay, away
    }
    
    struct SecurityEvent: Identifiable {
        let id: UUID
        let timestamp: Date
        let type: EventType
        let deviceName: String
        let severity: Severity
        
        enum EventType {
            case lockOpened, lockClosed, motionDetected, doorOpened, windowOpened
        }
        
        enum Severity {
            case info, warning, critical
        }
    }
    
    func arm(mode: SecurityStatus) {
        securityStatus = mode
        logEvent("Security system armed: \(mode)")
    }
    
    func logEvent(_ message: String) {
    }
}
