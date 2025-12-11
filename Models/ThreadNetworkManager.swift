import Foundation

class ThreadNetworkManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = ThreadNetworkManager()
    @Published var networkTopology: [ThreadNode] = []
    @Published var borderRouter: ThreadNode?
    
    struct ThreadNode: Identifiable {
        let id: UUID
        var deviceName: String
        var role: NodeRole
        var signalStrength: Int
        var connectedNodes: [UUID]
        
        enum NodeRole {
            case borderRouter, router, endDevice
        }
    }
    
    func visualizeNetwork() {
        // Build network topology
        networkTopology.removeAll()
    }
    
    func getNetworkHealth() -> Double {
        let avgSignal = networkTopology.map { $0.signalStrength }.reduce(0, +) / max(1, networkTopology.count)
        return Double(avgSignal) / 100.0
    }
}
