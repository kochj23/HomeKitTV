import Foundation
import GroupActivities

class SharePlayManager: ObservableObject {

    /// Cleans up resources to prevent memory leaks
    deinit {
        // Singleton cleanup - future-proofing for observers or timers
    }

    static let shared = SharePlayManager()
    @Published var isSharePlayActive: Bool = false
    
    struct HomeControlActivity: GroupActivity {
        static let activityIdentifier = "com.homekittv.homecontrol"
        
        var metadata: GroupActivityMetadata {
            var metadata = GroupActivityMetadata()
            metadata.title = "Control Home Together"
            metadata.type = .generic
            return metadata
        }
    }
    
    func startSharePlay() async throws {
        let activity = HomeControlActivity()
        _ = try await activity.prepareForActivation()
        isSharePlayActive = true
    }
}
