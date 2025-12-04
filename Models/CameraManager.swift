import Foundation
import HomeKit

class CameraManager: ObservableObject {
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