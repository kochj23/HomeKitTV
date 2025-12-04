import Foundation
import HomeKit

class MultiHomeManager: ObservableObject {
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