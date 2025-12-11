import Foundation
import HomeKit

class CameraManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = CameraManager()
    @Published var cameras: [HMCameraProfile] = []
    @Published var snapshots: [String: Data] = [:]
    
    func loadCameras(_ accessories: [HMAccessory]) {
        cameras = accessories.compactMap { $0.cameraProfiles?.first }
    }
    
    func getSnapshot(for camera: HMCameraProfile) async throws -> Data? {
        // Implementation for camera snapshot
        return nil
    }
}
