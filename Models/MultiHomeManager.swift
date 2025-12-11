import Foundation
import HomeKit

class MultiHomeManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = MultiHomeManager()
    @Published var homes: [HMHome] = []
    @Published var selectedHome: HMHome?
    
    func switchHome(_ home: HMHome) {
        selectedHome = home
    }
    
    func getAggregatedDeviceCount() -> Int {
        homes.reduce(0) { $0 + $1.accessories.count }
    }
}
